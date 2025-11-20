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
	
