.extern bootloader_startup
.extern app_start

.equ RAM_START,         0x20000000
.equ SCB_VTOR,          0xE000ED08

.equ magic_value_lo,    0x01234567
.equ magic_value_hi,    0x0089abcd

@ boot arguments:
@   0 : bootloader, with timeout (default)
@   1 : bootloader, without timeout
@   2 : application, RAM content is not altered
@   3 : ST bootloader

.thumb
.thumb_func
.syntax unified
.section .text
.global reset_handler
reset_handler:
    ldr     r5, =RAM_START
    ldr     r1, [r5, #0]    @ load magic value from RAM
    ldr     r2, [r5, #4]
    ldr     r4, =0x00FFFFFF
    and     r2, r2, r4

    eor     r0, r0          @ clear argument register

    ldr     r3, =magic_value_lo
    cmp     r1, r3
    bne     bootloader_startup
    ldr     r3, =magic_value_hi
    cmp     r2, r3
    bne     bootloader_startup

    @ magic value was correct
    ldrb    r0, [r5, #7]    @ load argument byte

    eor     r1, r1
    str     r1, [r5, #0]    @ clear ram_start
    str     r1, [r5, #4]

    cmp     r0, #2
    beq     _app_jmp
    cmp     r0, #3
    beq     _st_bootloader
    @ default: launch bootloader, argument r0
    b       bootloader_startup

_app_jmp:
    ldr     r0, =app_start
    ldr     r1, =SCB_VTOR
    str     r0, [r1]        @ relocate vector table
    dsb
    ldr     sp, [r0, #0]    @ initialize stack pointer
    ldr     r0, [r0, #4]    @ load reset address
    bx      r0              @ jump to application

_st_bootloader:
    ldr     r0, =0x1FFF0000
    ldr     sp, [r0, #0]
    ldr     r0, [r0, #4]
    bx      r0
