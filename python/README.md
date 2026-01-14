# CNN Model Training & Quantization

FPGA 하드웨어 가속기 탑재를 위해, PyTorch로 CNN 모델을 학습시키고 **가중치(Weights)를 추출하는 전처리 코드**입니다.

##  Workflow

### 1. Model Training (`train_cnn.py`)
* **Structure:** Conv(3x3) - ReLU - MaxPool - FC
* **Dataset:** 28x28 Grayscale Images (Custom Dataset)
* **Goal:** 객체 분류를 위한 기본 정확도 확보.

### 2. Quantization (양자화)
FPGA의 리소스(DSP, BRAM) 효율을 높이기 위해 부동소수점(Float32)을 고정소수점(Fixed-point)으로 변환합니다.
* **Scaling Factor:** 가중치 값에 `x128` (또는 `x64`)를 곱하여 정수화(Integer).
* **Benefit:** 하드웨어 연산 속도 향상 및 로직 사이즈 감소.

### 3. Header Export
* 학습된 파라미터(Weight, Bias)를 C/Verilog에서 읽을 수 있는 **Hex Array 포맷** (`weights.h`)으로 변환하여 저장합니다.

##  Usage
```bash
# 1. 학습 및 양자화 실행
python train_cnn.py --epoch 50 --quantize true

# 2. 생성된 헤더 파일을 Vivado 프로젝트로 복사
cp weights.h ../verilog/cnn/include/
