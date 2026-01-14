# Embedded Software (Tracking Controller)

Zynq PS(Processing System)에서 동작하는 Bare-metal 펌웨어입니다.
현재 **Stage(Tracking) 하드웨어**와 연동하여 실시간 객체 정렬을 수행합니다.

##  Control FSM (`main.c`)
시스템은 사용자 입력(UART)과 센서 데이터에 따라 3가지 상태로 동작합니다.

### 1. STATE_IDLE (대기)
* 초기화 완료 후 대기 상태.
* `Stage IP`로부터 현재 객체 좌표(Cur_X, Cur_Y)를 실시간 모니터링.

### 2. STATE_MANUAL (수동 제어)
* **UART Command:** 키보드 `w`, `a`, `s`, `d` 입력을 받아 스텝 모터를 수동으로 조작.
* 하드웨어 및 기구부 동작 테스트 용도.

### 3. STATE_AUTO (자동 정렬)
* **Algorithm:**
    * 목표 좌표(Target)와 현재 좌표(Current)의 오차(Error) 계산.
    * 오차 범위(Threshold) 내에 들어오도록 X/Y축 모터 드라이버 제어.
    * 정렬 완료 시 `STATE_SUCCESS`로 진입하여 모터 정지.

##  Hardware Interface
* **Camera & Stage IP Control:**
    * `CAMERA_IP_BASEADDR`를 통해 객체 좌표 수신.
* **Stepper Motor Control:**
    * `STEPPER_BASE_ADDR`를 통해 AXI GPIO로 펄스 생성 명령 전달.

##  Future Work
* 정렬이 완료된 시점(`STATE_SUCCESS`)에서 CNN 가속기 IP를 트리거(Trigger)하는 로직 추가 예정.
