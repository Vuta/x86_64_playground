  # This program accepts a filename and counts the number of words in that file
  # Algorithm:
  #   1) Maintain two variables
  #     a) state - OUT / IN
  #     b) count - 0
  #   2) Loop through each character
  #   3) If the character is a space, newline, or tab
  #      - set state = OUT
  #      - else if state is OUT
  #        1) set state = IN
  #        2) increase count by one

  # Processing:
  # 1) Open the input file
  #    - %rax - system call number 2
  #    - %rdi - the name of the file
  #    - %rsi - 0 for read-only mode
  #    - %rdx - $0666 for linux permission
  #    - effect: %rax - hold the fd
  # 2) Loop until EOF
  #    a) read bytes into memory buffer
  #       - %rax - system call number 0
  #       - %rdi - hold input file fd
  #       - %rsi - hold buffer address
  #       - %rdx - hold the buffer size
  #       - effect: %rax - hold the number of bytes that is read (0 means EOF)
  #    b) count from the buffer

  .section .data
msg:
  .equ SYS_READ, 0
  .equ SYS_WRITE, 1
  .equ SYS_OPEN, 2
  .equ SYS_CLOSE, 3
  .equ SYS_EXIT, 60

  .equ O_RDONLY, 0
  .equ STDOUT, 1 # output to STDOUT

  .equ STA_OUT, 0
  .equ STA_IN, 1 

  .equ END_OF_FILE, 0

  .section .bss
  .equ BUFFER_SIZE, 500
  .lcomm BUFFER_DATA, BUFFER_SIZE

  .section .text

  .equ ST_ARGV_1, 16 # name of the input file
  .globl _start
_start:
  movq %rsp, %rbp
open_input_file:  
  movq $SYS_OPEN, %rax
  movq ST_ARGV_1(%rbp), %rdi
  movq $O_RDONLY, %rsi
  movq $0666, %rdx
  syscall

  movq %rax, %r8 # store input fd
  movq $0, %r12 # this is the count result

read_input_file:
  movq $SYS_READ, %rax
  movq %r8, %rdi
  movq $BUFFER_DATA, %rsi
  movq $BUFFER_SIZE, %rdx
  syscall

  cmpq $END_OF_FILE, %rax
  jle end_read

  pushq %rax # 24(%rbp)
  pushq $BUFFER_DATA # 16(%rbp)
  call count_word # ret at 8(%rbp)
  addq $16, %rsp

  addq %r10, %r12

  jmp read_input_file

end_read:
  movq $SYS_CLOSE, %rax
  movq %r8, %rbx
  syscall

write_output: 
  # Currently, output is returned as exit status code
  # in movq %r12, %rdi
  # TODO: Write output to STDOUT
exit_program: 
  movq $SYS_EXIT, %rax
  movq %r12, %rdi
  syscall

count_word:
  pushq %rbp
  movq %rsp, %rbp

  movq 16(%rbp), %rax # buffer location
  movq 24(%rbp), %rdi # number of bytes to loop
  movq $STA_OUT, %r9 # init state
  movq $0, %r10 # init count
  movq $0, %r11

start_loop:
  cmpq %rdi, %r11
  je end_loop

  movb (%rax, %r11, 1), %cl
  cmpb $32, %cl
  je set_out_state
  cmpb $10, %cl
  je set_out_state
  cmpb $9, %cl
  je set_out_state

  cmpq $STA_OUT, %r9 
  jne next_loop

  movq $STA_IN, %r9
  incq %r10
  incq %r11
  jmp start_loop

set_out_state:
  movq $STA_OUT, %r9 
  incq %r11
  jmp start_loop
next_loop:
  incq %r11
  jmp start_loop
  
end_loop:
  movq %rbp, %rsp
  popq %rbp
  ret
