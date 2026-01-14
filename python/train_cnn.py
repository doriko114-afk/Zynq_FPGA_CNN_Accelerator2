import os
import cv2
import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader
from torchvision import datasets, transforms
import shutil
import random
import math

def simulate_fpga_pipeline(img):
    h, w = img.shape
    stripe_mask = np.zeros((h, w), dtype=np.uint8)
    offset = random.randint(0, 1)
    stripe_mask[:, offset::2] = 255
    striped_img = cv2.bitwise_and(img, stripe_mask)
    k_width = random.choice([2, 3])
    kernel = np.ones((1, k_width), np.uint8)
    smeared_img = cv2.dilate(striped_img, kernel, iterations=1)
    return smeared_img

def rotate_points(points, center, angle_deg):
    angle_rad = math.radians(angle_deg)
    cos_theta = math.cos(angle_rad)
    sin_theta = math.sin(angle_rad)
    cx, cy = center
    rotated_points = []
    for (x, y) in points:
        tx = x - cx
        ty = y - cy
        nx = tx * cos_theta - ty * sin_theta
        ny = tx * sin_theta + ty * cos_theta
        rotated_points.append([int(nx + cx), int(ny + cy)])
    return np.array(rotated_points, np.int32)

def reset_dataset():
    if os.path.exists("shapes_dataset"):
        shutil.rmtree("shapes_dataset")
    dirs = ["train/i", "train/o", "train/w", "test/i", "test/o", "test/w"]
    for d in dirs:
        os.makedirs(f"shapes_dataset/{d}", exist_ok=True)

def generate_centered_shape(label):
    src_size = 150
    roi_size = 112
    canvas = np.zeros((src_size, src_size), dtype=np.uint8)
    center = (src_size // 2, src_size // 2)
    cx, cy = center
    color = 255
    angle = random.randint(-60, 60)
    base_size = int(roi_size * random.uniform(0.75, 0.95))

    if label == "w":
        axes = (base_size // 2, int(base_size // 2 * random.uniform(0.9, 1.0)))
        thickness = random.randint(20, 30)
        cv2.ellipse(canvas, center, axes, angle, 0, 360, color, thickness)

    elif label == "o":
        w = base_size
        thickness = random.randint(20, 30)
        pt1 = (cx - w//2, cy - w//2); pt2 = (cx - w//4, cy + w//2)
        pt3 = (cx, cy); pt4 = (cx + w//4, cy + w//2); pt5 = (cx + w//2, cy - w//2)
        points = [pt1, pt2, pt3, pt4, pt5]
        rotated_pts = rotate_points(points, center, angle)
        cv2.polylines(canvas, [rotated_pts], False, color, thickness)

    elif label == "i":
        h = base_size
        stem_w = random.randint(30, 50)
        cap_w = int(stem_w * random.uniform(1.6, 2.2))
        cap_h = random.randint(20, 30)
        rect_stem = [(cx - stem_w//2, cy - h//2), (cx + stem_w//2, cy - h//2),
                     (cx + stem_w//2, cy + h//2), (cx - stem_w//2, cy + h//2)]
        rect_top  = [(cx - cap_w//2, cy - h//2), (cx + cap_w//2, cy - h//2),
                     (cx + cap_w//2, cy - h//2 + cap_h), (cx - cap_w//2, cy - h//2 + cap_h)]
        rect_bot  = [(cx - cap_w//2, cy + h//2 - cap_h), (cx + cap_w//2, cy + h//2 - cap_h),
                     (cx + cap_w//2, cy + h//2), (cx - cap_w//2, cy + h//2)]
        for rect in [rect_stem, rect_top, rect_bot]:
            rotated = rotate_points(rect, center, angle)
            cv2.fillPoly(canvas, [rotated], color)

    simulated_img = simulate_fpga_pipeline(canvas)
    start = (src_size - roi_size) // 2
    crop = simulated_img[start:start+roi_size, start:start+roi_size]
    small_img = cv2.resize(crop, (28, 28), interpolation=cv2.INTER_NEAREST)
    _, bin_img = cv2.threshold(small_img, 127, 255, cv2.THRESH_BINARY)
    if cv2.countNonZero(bin_img) < 30:
        return generate_centered_shape(label)
    dx = random.randint(-3, 3)
    dy = random.randint(-3, 3)
    M = np.float32([[1, 0, dx], [0, 1, dy]])
    shifted_img = cv2.warpAffine(bin_img, M, (28, 28))
    return shifted_img

class FPGA_CNN(nn.Module):
    def __init__(self):
        super(FPGA_CNN, self).__init__()
        self.conv = nn.Conv2d(1, 4, kernel_size=3, stride=1, padding=0, bias=True)
        self.relu = nn.ReLU()
        self.pool = nn.MaxPool2d(2, 2)
        self.flatten = nn.Flatten()
        self.dropout = nn.Dropout(0.5)
        self.fc = nn.Linear(13 * 13 * 4, 3, bias=True)

    def forward(self, x):
        x = self.conv(x)
        x = self.relu(x)
        x = self.pool(x)
        x = self.flatten(x)
        x = self.dropout(x)
        x = self.fc(x)
        return x

def run_training():
    reset_dataset()
    print(" Generating Dataset (i/o/w)...")
    labels = ["i", "o", "w"]
    for label in labels:
        for i in range(12000):
            img = generate_centered_shape(label)
            cv2.imwrite(f"shapes_dataset/train/{label}/{label}_{i}.png", img)
        for i in range(3000):
            img = generate_centered_shape(label)
            cv2.imwrite(f"shapes_dataset/test/{label}/{label}_{i}.png", img)

    print("\n 학습 시작 (Epoch 20)...")
    transform = transforms.Compose([transforms.Grayscale(), transforms.ToTensor()])
    train_data = datasets.ImageFolder("shapes_dataset/train", transform=transform)
    test_data = datasets.ImageFolder("shapes_dataset/test", transform=transform)
    train_loader = DataLoader(train_data, batch_size=64, shuffle=True)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = FPGA_CNN().to(device)
    optimizer = optim.Adam(model.parameters(), lr=0.001)
    criterion = nn.CrossEntropyLoss()

    for epoch in range(20):
        model.train()
        correct = 0; total = 0
        for img, label in train_loader:
            img, label = img.to(device), label.to(device)
            img = (img > 0.5).float()
            optimizer.zero_grad()
            output = model(img)
            loss = criterion(output, label)
            loss.backward()
            optimizer.step()
            _, predicted = torch.max(output.data, 1)
            total += label.size(0)
            correct += (predicted == label).sum().item()
        print(f"Epoch {epoch+1}: Acc = {100 * correct / total:.2f}%")

    print("\n Verilog 파라미터 출력 ")
    model.cpu()
    SCALE = 10
    conv_w = model.conv.weight.data.numpy()
    conv_b = model.conv.bias.data.numpy()
    
    for ch in range(4):
        k = conv_w[ch, 0]; b = conv_b[ch]
        print(f"// Ch{ch}")
        print(f".k00_ch{ch}({int(k[0][0]*SCALE)}), .k01_ch{ch}({int(k[0][1]*SCALE)}), .k02_ch{ch}({int(k[0][2]*SCALE)}),")
        print(f".k10_ch{ch}({int(k[1][0]*SCALE)}), .k11_ch{ch}({int(k[1][1]*SCALE)}), .k12_ch{ch}({int(k[1][2]*SCALE)}),")
        print(f".k20_ch{ch}({int(k[2][0]*SCALE)}), .k21_ch{ch}({int(k[2][1]*SCALE)}), .k22_ch{ch}({int(k[2][2]*SCALE)}),")
        print(f".bias_ch{ch}({int(b*SCALE)}),")

    # FC Layer 파라미터 출력
    fc_w = model.fc.weight.data.numpy()
    fc_b = model.fc.bias.data.numpy()
    idx_to_class = {v: k for k, v in train_data.class_to_idx.items()}

    print("\n// FC Layer Parameters")
    print(f"// class mapping: {idx_to_class}")
    print(f"localparam signed [31:0] BIAS_0 = {int(fc_b[0]*SCALE)};")
    print(f"localparam signed [31:0] BIAS_1 = {int(fc_b[1]*SCALE)};")
    print(f"localparam signed [31:0] BIAS_2 = {int(fc_b[2]*SCALE)};")

    def print_fc_weights(name, weight_arr):
        print(f"localparam signed [7:0] {name} [0:{len(weight_arr)-1}] = '{{")
        vals = [str(int(x * SCALE)) for x in weight_arr]
        for i in range(0, len(vals), 13):
            line = ", ".join(vals[i:i+13])
            if i + 13 < len(vals): line += ","
            print(f"    {line}")
        print("};")

    print_fc_weights("W_0", fc_w[0])
    print_fc_weights("W_1", fc_w[1])
    print_fc_weights("W_2", fc_w[2])

if __name__ == "__main__":
    run_training()
