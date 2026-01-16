# Hardware Design (Independent Modules)

본 프로젝트의 하드웨어(PL)는 **객체 추적을 위한 `Stage` 모듈**과 **객체 식별을 위한 `CNN` 모듈**로 나뉘어 있습니다.
각 모듈은 독립적인 기능을 수행하며 AXI 버스를 통해 PS와 데이터를 주고받습니다.

##  Modules Description

### 1. Object Tracking Module (`/stage`)
**"객체를 화면 중앙으로 옮기기 위한 좌표 추출기"**
* **Role:** 카메라 입력 영상에서 객체를 인식하고, 모터 제어에 필요한 좌표 정보를 생성합니다.
* **Logic:**
    * **Img_Process:** RGB to Grayscale 변환 및 이진화(Thresholding).
    * **Center of Gravity (CoG):** 픽셀들의 평균 위치를 계산하여 객체의 현재 X, Y 좌표를 실시간으로 출력.
    * **Output:** 현재 객체의 좌표 데이터 -> AXI 레지스터를 통해 PS(SW)가 판독.

### 2. AI Inference Module (`/cnn`)
**"정렬된 객체를 식별하는 가속기"**
* **Role:** 특정 영역(ROI)의 이미지 데이터를 입력받아 CNN 연산을 수행합니다.
* **Logic:**
    * **Line Buffer:** 스트리밍 데이터 처리를 위한 윈도우 버퍼링.
    * **Accelerator:** Conv(3x3) -> Pool(2x2) -> ReLU -> FC 구조의 하드웨어 가속기.
* **Feature:** 학습된 가중치를 내장하여 외부 메모리 접근 없이 고속 연산 처리.

---

##  Future Plan: Integration
* 현재 분리되어 있는 좌표 추출(Stage)과 **추론(CNN)** 로직을 하나의 파이프라인으로 통합하여, 정렬과 동시에 추론이 가능한 **Unified SoC**로 발전시킬 계획입니다.

