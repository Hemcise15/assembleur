; external functions from X11 library
extern XOpenDisplay
extern XDisplayName
extern XCloseDisplay
extern XCreateSimpleWindow
extern XMapWindow
extern XRootWindow
extern XSelectInput
extern XFlush
extern XCreateGC
extern XSetForeground
extern XDrawLine
extern XDrawPoint
extern XFillArc
extern XNextEvent

; external functions from stdio library (ld-linux-x86-64.so.2)
extern printf
extern exit

%define	StructureNotifyMask	131072
%define KeyPressMask		1
%define ButtonPressMask		4
%define MapNotify		19
%define KeyPress		2
%define ButtonPress		4
%define Expose			12
%define ConfigureNotify		22
%define CreateNotify 16
%define QWORD	8
%define DWORD	4
%define WORD	2
%define BYTE	1

%define SCREEN_W 400
%define SCREEN_H 400

global main

section .data

event:		times	24 dq 0

section .bss
    display_name:	resq	1
    screen:		resd	1
    depth:         	resd	1
    connection:    	resd	1
    width:         	resd	1
    height:        	resd	1
    window:		resq	1
    gc:		resq	1
    A_x: resd 1
    A_y: resd 1
    B_x: resd 1
    B_y: resd 1
    C_x: resd 1
    C_y: resd 1
    xmin: resd 1
    xmax: resd 1
    ymin: resd 1
    ymax: resd 1
    tri_det: resd 1
    P_x: resd 1
    P_y: resd 1

section .text

random_int:
random_retry:
    rdrand eax
    jnc random_retry
    xor edx, edx
    div edi
    mov eax, edx
ret

generate_triangle:
    mov edi, SCREEN_W
    call random_int
    mov [A_x], eax

    mov edi, SCREEN_H
    call random_int
    mov [A_y], eax

    mov edi, SCREEN_W
    call random_int
    mov [B_x], eax

    mov edi, SCREEN_H
    call random_int
    mov [B_y], eax

    mov edi, SCREEN_W
    call random_int
    mov [C_x], eax

    mov edi, SCREEN_H
    call random_int
    mov [C_y], eax
ret

det_points:
    mov eax, [rdx]
    sub eax, [rdi]
    
    mov ebx, [rcx]
    sub ebx, [rsi]
    
    mov ecx, [r8]
    sub ecx, [rdi]
    
    mov edx, [r9]
    sub edx, [rsi]
    
    mov eax, ecx
    imul ebx
    
    sub esi, eax
    mov eax, esi
ret

draw_triangle:
    mov rdi, [display_name]
    mov rsi, [gc]
    mov edx, 0x000000
    call XSetForeground

    mov rdi, [display_name]
    mov rsi, [window]
    mov rdx, [gc]
    mov ecx, [A_x]
    mov r8d, [A_y]
    mov r9d, [B_x]
    push qword[B_y]
    call XDrawLine
    add rsp, 8

    mov rdi, [display_name]
    mov rsi, [window]
    mov rdx, [gc]
    mov ecx, [B_x]
    mov r8d, [B_y]
    mov r9d, [C_x]
    push qword[C_y]
    call XDrawLine
    add rsp, 8

    mov rdi, [display_name]
    mov rsi, [window]
    mov rdx, [gc]
    mov ecx, [C_x]
    mov r8d, [C_y]
    mov r9d, [A_x]
    push qword[A_y]
    call XDrawLine
    add rsp, 8
ret

fill_triangle:
     mov eax, [A_x]
     mov ebx, [B_x]
     mov ecx, [C_x]
     
     mov edx, eax
     cmp ebx, edx
     jge min_x_skip1
     mov edx, ebx
min_x_skip1:
     cmp ecx, edx
     jge min_x_done
     mov edx, ecx
min_x_done:
     mov [xmin], edx
     
     mov edx, eax
     cmp ebx, edx
     jle max_x_skip1
     mov edx, ebx
max_x_skip1:
     cmp ecx, edx
     jle max_x_done
     mov edx, ecx
max_x_done:
     mov [xmax], edx
     
     mov eax, [A_y]
     mov ebx, [B_y]
     mov ecx, [C_y]
     
     mov edx, eax
     cmp ebx, edx
     jge min_y_skip1
     mov edx, ebx
min_y_skip1:
     cmp ecx, edx
     jge min_y_done
     mov edx, ecx
min_y_done:
     mov [ymin], edx
     
     mov edx, eax
     cmp ebx, edx
     jle max_y_skip1
     mov edx, ebx
max_y_skip1:
     cmp ecx, edx
     jle max_y_done
     mov edx, ecx
max_y_done:
     mov [ymax], edx
     
     mov eax, [A_x]
     sub eax, [B_x]
     
     mov ebx, [A_y]
     sub ebx, [B_y]
     
     mov ecx, [C_x]
     sub ecx, [B_x]
     
     mov edx, [C_y]
     sub edx, [B_y]
     
     mov esi, eax
     imul edx
     mov edi, eax
     
     mov eax, ecx
     imul ebx
     sub edi, eax
     mov [tri_det], edi
     
     mov esi, [ymin]
y_loop:
     cmp esi, [ymax]
     jg end_fill
     
     mov edi, [xmin]
x_loop:
     cmp edi, [xmax]
     jg next_row
     
     mov [P_x], edi
     mov [P_y], esi
     
     mov rdi, A_x
     mov rsi, A_y
     mov rdx, B_x
     mov rcx, B_y
     mov r8, P_x
     mov r9, P_y
     call det_points
     mov ebx, eax
     
     mov rdi, B_x
     mov rsi, B_y
     mov rdx, C_x
     mov rcx, C_y
     mov r8, P_x
     mov r9, P_y
     call det_points
     mov ecx, eax
     
     mov rdi, C_x
     mov rsi, C_y
     mov rdx, A_x
     mov rcx, A_y
     mov r8, P_x
     mov r9, P_y
     call det_points
     mov edx, eax
     
     mov eax, [tri_det]
     cmp eax, 0
     jl triangle_direct
     jg triangle_indirect
     jmp skip_draw
     
triangle_direct:
     cmp ebx, 0
     jle skip_draw
     cmp ecx, 0
     jle skip_draw
     cmp edx, 0
     jle skip_draw
     jmp draw_point
triangle_indirect:
     cmp ebx, 0
     jge skip_draw
     cmp ecx, 0
     jge skip_draw
     cmp edx, 0
     jge skip_draw
     jmp draw_point
draw_point:
     mov rdi, [display_name]
     mov rsi, [window]
     mov rdx, [gc]
     mov ecx, edi
     mov r8d, esi
     call XDrawPoint
skip_draw:
     inc edi
     jmp x_loop
next_row: 
     inc esi
     jmp y_loop
end_fill:
ret

;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

main:
xor     rdi,rdi
call    XOpenDisplay	; Création de display
mov     qword[display_name],rax	; rax=nom du display

; display_name structure
; screen = DefaultScreen(display_name);
mov     rax,qword[display_name]
mov     eax,dword[rax+0xe0]
mov     dword[screen],eax

mov rdi,qword[display_name]
mov esi,dword[screen]
call XRootWindow
mov rbx,rax

mov rdi,qword[display_name]
mov rsi,rbx
mov rdx,10
mov rcx,10
mov r8,400	; largeur
mov r9,400	; hauteur
push 0xFFFFFF	; background  0xRRGGBB
push 0x00FF00
push 1
call XCreateSimpleWindow
mov qword[window],rax

mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,131077 ;131072
call XSelectInput

mov rdi,qword[display_name]
mov rsi,qword[window]
call XMapWindow

mov rsi,qword[window]
mov rdx,0
mov rcx,0
call XCreateGC
mov qword[gc],rax

mov rdi,qword[display_name]
mov rsi,qword[gc]
mov rdx,0x000000	; Couleur du crayon
call XSetForeground

boucle: ; boucle de gestion des évènements
mov rdi,qword[display_name]
mov rsi,event
call XNextEvent

cmp dword[event],ConfigureNotify	; à l'apparition de la fenêtre
je dessin							; on saute au label 'dessin'

cmp dword[event],KeyPress			; Si on appuie sur une touche
je closeDisplay						; on saute au label 'closeDisplay' qui ferme la fenêtre
jmp flush

;#########################################
;#	DEBUT DE LA ZONE DE DESSIN	 #
;#########################################
dessin:
    call generate_triangle
    call fill_triangle
    call draw_triangle
    jmp flush


; ############################
; # FIN DE LA ZONE DE DESSIN #
; ############################

flush:
    mov rdi,qword[display_name]
    call XFlush
    jmp boucle

closeDisplay:
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit
	
