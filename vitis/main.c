/*
 * OV7670 + Linear Stage: Hybrid Tracking System (Auto/Manual)
 * Features: Inverted Auto Logic, Manual WASD Control, 'm' Mode Switch
 */

#include <stdio.h>
#include "xil_printf.h"
#include "xil_io.h"
#include "sleep.h"
#include "xparameters.h"
#include "xuartps_hw.h"

// =========================================================================
// [1] 주소 및 레지스터 정의
// =========================================================================
#define CAMERA_IP_BASEADDR  XPAR_MYIP_SINGLE_OV7670_0_S00_AXI_BASEADDR
#define GPIO_BASEADDR       XPAR_AXI_GPIO_0_BASEADDR
#define UART_BASEADDR       XPAR_XUARTPS_0_BASEADDR
#define STEPPER_BASE_ADDR   XPAR_MY_2STEPPER_IP_0_BASEADDR

// Camera
#define REG_CTRL_OFFSET     0x00
#define REG_READ_X_OFFSET   0x08
#define REG_READ_Y_OFFSET   0x0C

// GPIO (Target)
#define GPIO_CH1_OFFSET     0x00 // Target X
#define GPIO_CH2_OFFSET     0x08 // Target Y

// Stepper Motor
#define M1_CTRL     0x00
#define M1_SPEED    0x04
#define M2_CTRL     0x08
#define M2_SPEED    0x0C

#define MOTOR_EN      0x01
#define MOTOR_CW      0x00
#define MOTOR_CCW     0x02

// =========================================================================
// [2] 시스템 설정값
// =========================================================================
#define SCREEN_WIDTH        640
#define SCREEN_HEIGHT       480

// [설정] 오차 범위 (5픽셀)
#define CENTER_MARGIN       5
#define TARGET_MOVE_STEP    10   // 타겟 박스 이동 속도
#define MOTOR_SPEED_FIXED   30000

// [상태 머신 정의]
#define STATE_IDLE      0  // 대기 (목표 설정)
#define STATE_AUTO      1  // 자동 추적
#define STATE_MANUAL    2  // 수동 조작 (모터 직접 제어)
#define STATE_SUCCESS   3  // 목표 도달 완료

// =========================================================================
// [3] 함수 정의
// =========================================================================
u8 is_uart_data_available() {
    return !(Xil_In32(UART_BASEADDR + XUARTPS_SR_OFFSET) & XUARTPS_SR_RXEMPTY);
}

u8 read_uart_char() {
    return Xil_In32(UART_BASEADDR + XUARTPS_FIFO_OFFSET);
}

void control_motor(int motor_id, int enable, int direction) {
    u32 ctrl_val = 0;
    u32 addr_ctrl = (motor_id == 1) ? M1_CTRL : M2_CTRL;

    if (enable) {
        ctrl_val = MOTOR_EN;
        if (direction == 1) ctrl_val |= MOTOR_CCW;
        else                ctrl_val |= MOTOR_CW;
    }
    Xil_Out32(STEPPER_BASE_ADDR + addr_ctrl, ctrl_val);
}

void stop_all_motors() {
    control_motor(1, 0, 0);
    control_motor(2, 0, 0);
}

int main()
{
    xil_printf("\r\n======================================================\r\n");
    xil_printf("   OV7670 Hybrid Tracking System (Auto/Manual)\r\n");
    xil_printf("   [IDLE] WASD: Move Target | 'g': Auto Run | 'm': Manual Mode\r\n");
    xil_printf("   [MANU] WASD: Move Motors Directly | 'x': Stop\r\n");
    xil_printf("======================================================\r\n");

    // 1. 모터 속도 초기화
    Xil_Out32(STEPPER_BASE_ADDR + M1_SPEED, MOTOR_SPEED_FIXED);
    Xil_Out32(STEPPER_BASE_ADDR + M2_SPEED, MOTOR_SPEED_FIXED);

    // 2. 목표 좌표 초기화
    int target_x = SCREEN_WIDTH / 2;
    int target_y = SCREEN_HEIGHT / 2;
    Xil_Out32(GPIO_BASEADDR + GPIO_CH1_OFFSET, target_x);
    Xil_Out32(GPIO_BASEADDR + GPIO_CH2_OFFSET, target_y);

    u32 detected_x, detected_y;
    u32 msg_code = 0;
    int diff_x = 0, diff_y = 0;
    int loop_cnt = 0;

    int current_state = STATE_IDLE;

    // 수동 모드용 임시 변수
    int manual_cmd_x = 0; // -1:Left, 0:Stop, 1:Right
    int manual_cmd_y = 0; // -1:Up, 0:Stop, 1:Down

    // 모터 상태 문자열
    char *m1_status_str = "STOP";
    char *m2_status_str = "STOP";

    while(1) {
        // -------------------------------------------------------------
        // [Step 1] 현재 좌표 읽기 및 차이 계산
        // -------------------------------------------------------------
        detected_x = Xil_In32(CAMERA_IP_BASEADDR + REG_READ_X_OFFSET);
        detected_y = Xil_In32(CAMERA_IP_BASEADDR + REG_READ_Y_OFFSET);

        if (detected_x != 0 || detected_y != 0) {
            diff_x = (int)detected_x - target_x;
            diff_y = (int)detected_y - target_y;
        } else {
            diff_x = 0; diff_y = 0;
        }

        int abs_diff_x = (diff_x < 0) ? -diff_x : diff_x;
        int abs_diff_y = (diff_y < 0) ? -diff_y : diff_y;

        // 수동 명령 초기화 (키를 누르고 있을 때만 움직이게 하기 위함)
        manual_cmd_x = 0;
        manual_cmd_y = 0;

        // -------------------------------------------------------------
        // [Step 2] UART 키 입력 처리
        // -------------------------------------------------------------
        if (is_uart_data_available()) {
            u8 key = read_uart_char();

            // [공통] 비상 정지 / 초기화 ('x')
            if (key == 'x' || key == 'X') {
                current_state = STATE_IDLE;
                msg_code = 0;
                stop_all_motors();
                xil_printf("\r\n>>> [STOP] Reset to IDLE <<<\r\n");
            }

            // [상태별 키 입력 처리]
            else if (current_state == STATE_IDLE || current_state == STATE_SUCCESS) {
                if (key == 'g' || key == 'G') {
                    current_state = STATE_AUTO;
                    msg_code = 0;
                    xil_printf("\r\n>>> [AUTO] Tracking Started... <<<\r\n");
                }
                else if (key == 'm' || key == 'M') {
                    current_state = STATE_MANUAL;
                    msg_code = 0;
                    xil_printf("\r\n>>> [MANUAL] WASD controls Motors directly. <<<\r\n");
                }
                else {
                    // IDLE 상태에서 WASD -> 목표 박스 이동
                    current_state = STATE_IDLE; // SUCCESS 해제
                    msg_code = 0;
                    int moved = 0;
                    if (key == 'w' || key == 'W') { target_y -= TARGET_MOVE_STEP; moved = 1; }
                    else if (key == 's' || key == 'S') { target_y += TARGET_MOVE_STEP; moved = 1; }
                    else if (key == 'a' || key == 'A') { target_x -= TARGET_MOVE_STEP; moved = 1; }
                    else if (key == 'd' || key == 'D') { target_x += TARGET_MOVE_STEP; moved = 1; }

                    if(target_x < 0) target_x = 0;
                    if(target_x > SCREEN_WIDTH) target_x = SCREEN_WIDTH;

                    if(target_y < 0) target_y = 0;
                    if(target_y > SCREEN_HEIGHT) target_y = SCREEN_HEIGHT;

                    if (moved) {
                        Xil_Out32(GPIO_BASEADDR + GPIO_CH1_OFFSET, target_x);
                        Xil_Out32(GPIO_BASEADDR + GPIO_CH2_OFFSET, target_y);
                    }
                }
            }
            else if (current_state == STATE_MANUAL) {
                // 수동 모드에서 WASD -> 모터 이동 명령
                if (key == 'w' || key == 'W') manual_cmd_y = 1; // M2 Up
                else if (key == 's' || key == 'S') manual_cmd_y = -1;  // M2 Down
                else if (key == 'a' || key == 'A') manual_cmd_x = -1; // M1 Right
                else if (key == 'd' || key == 'D') manual_cmd_x = 1;  // M1 Left
            }
        }

        // -------------------------------------------------------------
        // [Step 3] 모터 제어 및 상태 머신 로직
        // -------------------------------------------------------------
        m1_status_str = "STOP";
        m2_status_str = "STOP";

        switch (current_state) {
            case STATE_IDLE:
                stop_all_motors();
                break;

            case STATE_AUTO:
                if (detected_x == 0 && detected_y == 0) {
                    stop_all_motors();
                }
                else {
                    // [중요] 자동 추적 로직 (방향 반전됨)
                    // 기존: diff > 0 (물체가 오른쪽) -> CW (오른쪽 이동) -> 멀어짐 (오류)
                    // 수정: diff > 0 (물체가 오른쪽) -> CCW (왼쪽 이동) -> 타겟 쪽으로 옴 (정답)

                    // --- X축 제어 (M1) ---
                    if (diff_x > CENTER_MARGIN) {
                        control_motor(1, 1, 1); // CCW (반대 방향)
                        m1_status_str = "AUTO <<<";
                    }
                    else if (diff_x < -CENTER_MARGIN) {
                        control_motor(1, 1, 0); // CW (반대 방향)
                        m1_status_str = "AUTO >>>";
                    }
                    else {
                        control_motor(1, 0, 0); // Stop
                        m1_status_str = "LOCKED";
                    }

                    // --- Y축 제어 (M2) ---
                    if (diff_y > CENTER_MARGIN) {
                        control_motor(2, 1, 0); // CCW (반대 방향)
                        m2_status_str = "AUTO ^^^";
                    }
                    else if (diff_y < -CENTER_MARGIN) {
                        control_motor(2, 1, 1); // CW (반대 방향)
                        m2_status_str = "AUTO vvv";
                    }
                    else {
                        control_motor(2, 0, 0); // Stop
                        m2_status_str = "LOCKED";
                    }

                    // 도달 판정
                    if (abs_diff_x < CENTER_MARGIN && abs_diff_y < CENTER_MARGIN) {
                        current_state = STATE_SUCCESS;
                        stop_all_motors();
                        msg_code = 1;
                    }
                }
                break;

            case STATE_MANUAL:
                // 수동 제어 로직 (키 입력이 있을 때만 동작)
                // X축 (AD)
                if (manual_cmd_x == 1) {
                    control_motor(1, 1, 0); // CW
                    m1_status_str = "MANU >>>";
                } else if (manual_cmd_x == -1) {
                    control_motor(1, 1, 1); // CCW
                    m1_status_str = "MANU <<<";
                } else {
                    control_motor(1, 0, 0); // Stop
                }

                // Y축 (WS)
                if (manual_cmd_y == 1) {
                    control_motor(2, 1, 0); // CW
                    m2_status_str = "MANU vvv";
                } else if (manual_cmd_y == -1) {
                    control_motor(2, 1, 1); // CCW
                    m2_status_str = "MANU ^^^";
                } else {
                    control_motor(2, 0, 0); // Stop
                }
                break;

            case STATE_SUCCESS:
                stop_all_motors();
                msg_code = 1;
                break;
        }

        Xil_Out32(CAMERA_IP_BASEADDR + REG_CTRL_OFFSET, msg_code);

        // -------------------------------------------------------------
        // [Step 4] 모니터링 출력
        // -------------------------------------------------------------
        loop_cnt++;
        if (loop_cnt % 5 == 0) {
            char *status_label = "UNKNOWN";
            if(current_state == STATE_IDLE) status_label = "IDLE";
            else if(current_state == STATE_AUTO) status_label = "AUTO";
            else if(current_state == STATE_MANUAL) status_label = "MANU";
            else if(current_state == STATE_SUCCESS) status_label = "SUCC";

            xil_printf("\r[%s] Tgt(%3d,%3d) Cur(%3d,%3d) | M1: %-8s | M2: %-8s   ",
                        status_label, target_x, target_y, detected_x, detected_y,
                        m1_status_str, m2_status_str);
        }

        usleep(50000); // 50ms
    }

    return 0;
}
