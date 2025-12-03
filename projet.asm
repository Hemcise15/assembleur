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
extern XDrawArc
extern XFillArc
extern XNextEvent

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
%define NBTRI	5
%define	LARGEUR 400	; largeur en pixels de la fenêtre
%define HAUTEUR 400	; hauteur en pixels de la fenêtre

global main
global alea_h
global alea_l
global generer_triangle
global triangle_vecteurs
global rectangle_calculer
global sens_triangle
global remplissage
global det_AB
global det_BC
global det_CA

section .bss
display_name:	resq	1
screen:		resd	1
depth:         	resd	1
connection:    	resd	1
width:         	resd	1
height:        	resd	1
window:		resq	1
gc:		resq	1

triangle_A:	resq 	2
triangle_B:	resq	2
triangle_C:	resq	2
rectangle:	resq	4
point:		resq	2
direct:		resb	1
AB_vec:		resq	2
BC_vec:		resq	2
CA_vec:		resq	2
nb_tr:		resq	1

section .data

event:		times	24 dq 0
passe: db 0
x1:	dd	0
x2:	dd	0
y1:	dd	0
y2:	dd	0

section .text
	
;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

alea_l:
    retry_l:
        rdrand rax
	jnc retry_l

	xor rdx, rdx
	mov rcx, LARGEUR
	div rcx
	mov rax, rdx
ret

alea_h:
    retry_h:
	rdrand rax
	jnc retry_h

	xor rdx, rdx
	mov rcx, HAUTEUR
	div rcx
	mov rax, rdx
ret

couleur_aleatoire:
     retry_color:
	rdrand rax
	jnc retry_color

	xor rdx, rdx
	mov rcx, 0x00FFFFFF
	div rcx
	mov edx, edx

	mov rdi, [display_name]
	mov rsi, [gc]
	call XSetForeground
ret

nb_triangles_alea:
    retry_nb:
	rdrand rax
	jnc retry_nb

	xor rdx, rdx
	mov rcx, 10
	div rcx

	mov rax, rdx
	inc rax
	mov [nb_tr], rax
ret

generer_triangle:
    call alea_l
    mov [triangle_A], rax
    call alea_h
    mov [triangle_A+QWORD], rax

    call alea_l
    mov [triangle_B], rax
    call alea_h
    mov [triangle_B+QWORD], rax

    call alea_l
    mov [triangle_C], rax
    call alea_h
    mov [triangle_C+QWORD], rax
ret

triangle_vecteurs:
    mov rax, [triangle_A]
    mov rbx, [triangle_A+QWORD]

    mov rcx, [triangle_B]
    mov rdx, [triangle_B+QWORD]

    mov r8, [triangle_C]
    mov r9, [triangle_C+QWORD]

    mov r10, rcx
    sub r10, rax
    mov [AB_vec], r10
    mov r11, rdx
    sub r11, rbx
    mov [AB_vec+QWORD], r11

    mov r10, r8
    sub r10, rcx
    mov [BC_vec], r10
    mov r11, r9
    sub r11, rdx
    mov [BC_vec+QWORD], r11

    mov r10, rax
    sub r10, r8
    mov [CA_vec], r10
    mov r11, rbx
    sub r11, r9
    mov [CA_vec+QWORD], r11
ret

rectangle_calculer:
    mov rax, [triangle_A]
    mov rbx, [triangle_B]
    mov rcx, [triangle_C]

    mov rdx, rax
    cmp rbx, rdx
    jge xmin_notB
    mov rdx, rbx
xmin_notB:
    cmp rcx, rdx
    jge xmin_notC
    mov rdx, rcx
xmin_notC:
    mov [rectangle], rdx

    mov rdx, rax
    cmp rbx, rdx
    jle xmax_notB
    mov rdx, rbx
xmax_notB:
    cmp rcx, rdx
    jle xmax_notC
    mov rdx, rcx
xmax_notC:
    mov [rectangle+QWORD], rdx

    mov rax, [triangle_A+QWORD]
    mov rbx, [triangle_B+QWORD]
    mov rcx, [triangle_C+QWORD]

    mov rdx, rax
    cmp rbx, rdx
    jge ymin_notB
    mov rdx, rbx
ymin_notB:
    cmp rcx, rdx
    jge ymin_notC
    mov rdx, rcx
ymin_notC:
    mov [rectangle+QWORD*2], rdx

    mov rdx, rax
    cmp rbx, rdx
    jle ymax_notB
    mov rdx, rbx
ymax_notB:
    cmp rcx, rdx
    jle ymax_notC
    mov rdx, rcx
ymax_notC:
    mov [rectangle+QWORD*3], rdx
ret

sens_triangle:
    mov rax, [triangle_A]
    mov rbx, [triangle_A+QWORD]

    mov rcx, [triangle_B]
    mov rdx, [triangle_B+QWORD]

    mov r8, [triangle_C]
    mov r9, [triangle_C+QWORD]

    mov r10, rax
    sub r10, rcx
    mov r11, rbx
    sub r11, rdx

    mov r12, r8
    sub r12, rcx
    mov r13, r9
    sub r13, rdx

    mov rax, r10
    imul rax, r13
    mov r14, r12
    imul r14, r11
    sub rax, r14

    cmp rax, 0
    jl .direct
    mov byte[direct], 0
    ret
.direct:
    mov byte[direct], 1
    ret

det_AB:
    mov rax, [triangle_A]
    mov rbx, [triangle_A+QWORD]
    mov rcx, [point]
    mov rdx, [point+QWORD]

    sub rcx, rax
    sub rdx, rbx

    mov r8, [AB_vec]
    mov r9, [AB_vec+QWORD]

    mov rax, r8
    imul rax, rdx
    mov r10, rcx
    imul r10, r9
    sub rax, r10
ret

det_BC:
    mov rax, [triangle_B]
    mov rbx, [triangle_B+QWORD]
    mov rcx, [point]
    mov rdx, [point+QWORD]

    sub rcx, rax
    sub rdx, rbx

    mov r8, [BC_vec]
    mov r9, [BC_vec+QWORD]

    mov rax, r8
    imul rax, rdx
    mov r10, rcx
    imul r10, r9
    sub rax, r10
ret

det_CA:
    mov rax, [triangle_C]
    mov rbx, [triangle_C+QWORD]
    mov rcx, [point]
    mov rdx, [point+QWORD]

    sub rcx, rax
    sub rdx, rbx

    mov r8, [CA_vec]
    mov r9, [CA_vec+QWORD]

    mov rax, r8
    imul rax, rdx
    mov r10, rcx
    imul r10, r9
    sub rax, r10
ret

remplissage:
    mov r15, [rectangle+QWORD*2]
    mov r13, [rectangle+QWORD*3]

boucle_y:
    cmp r15, r13
    jg fin_y
    mov r14, [rectangle]
    mov r12, [rectangle+QWORD]

boucle_x:
    cmp r14, r12
    jg fin_x
    mov [point], r14
    mov [point+QWORD], r15
    cmp byte[direct], 1
    je test_direct
    jmp test_indirect

test_direct:
    call det_AB
    cmp rax, 0
    jl not_in
    call det_BC
    cmp rax, 0
    jl not_in
    call det_CA
    cmp rax, 0
    jl not_in
    jmp in

test_indirect:
    call det_AB
    cmp rax, 0
    jg not_in
    call det_BC
    cmp rax, 0
    jg not_in
    call det_CA
    cmp rax, 0
    jg not_in
    jmp in

in:
    mov rdi, qword[display_name]
    mov rsi, qword[window]
    mov rdx, qword[gc]
    mov ecx, dword[point]
    mov r8d, dword[point+QWORD]
    call XDrawPoint
    jmp after

not_in:
after:
    inc r14
    jmp boucle_x
fin_x:
    inc r15
    jmp boucle_y
fin_y:
    ret

main:
    ; Sauvegarde du registre de base pour préparer les appels à printf
    push    rbp
    mov     rbp, rsp
	
    ; Récupère le nom du display par défaut (en passant NULL)
    xor     rdi, rdi          ; rdi = 0 (NULL)
    call    XDisplayName      ; Appel de la fonction XDisplayName
    ; Vérifie si le display est valide
    test    rax, rax          ; Teste si rax est NULL
    jz      closeDisplay      ; Si NULL, ferme le display et quitte

    ; Ouvre le display par défaut
    xor     rdi, rdi          ; rdi = 0 (NULL pour le display par défaut)
    call    XOpenDisplay      ; Appel de XOpenDisplay
    test    rax, rax          ; Vérifie si l'ouverture a réussi
    jz      closeDisplay      ; Si échec, ferme le display et quitte

    ; Stocke le display ouvert dans la variable globale display_name
    mov     [display_name], rax

    ; Récupère la fenêtre racine (root window) du display
    mov     rdi,qword[display_name]   ; Place le display dans rdi
    mov     esi,dword[screen]         ; Place le numéro d'écran dans esi
    call XRootWindow                ; Appel de XRootWindow pour obtenir la fenêtre racine
    mov     rbx,rax               ; Stocke la root window dans rbx

    ; Création d'une fenêtre simple
    mov     rdi,qword[display_name]   ; display
    mov     rsi,rbx                   ; parent = root window
    mov     rdx,10                    ; position x de la fenêtre
    mov     rcx,10                    ; position y de la fenêtre
    mov     r8,LARGEUR                ; largeur de la fenêtre
    mov     r9,HAUTEUR           	; hauteur de la fenêtre
    push 0x000000                     ; couleur du fond (noir, 0x000000)
    push 0x00FF00                     ; couleur de fond (vert, 0x00FF00)
    push 1                          ; épaisseur du bord
    call XCreateSimpleWindow        ; Appel de XCreateSimpleWindow
	add rsp,24
	mov qword[window],rax           ; Stocke l'identifiant de la fenêtre créée dans window

    ; Sélection des événements à écouter sur la fenêtre
    mov rdi,qword[display_name]
    mov rsi,qword[window]
    mov rdx,131077                 ; Masque d'événements (ex. StructureNotifyMask + autres)
    call XSelectInput

    ; Affichage (mapping) de la fenêtre
    mov rdi,qword[display_name]
    mov rsi,qword[window]
    call XMapWindow

    ; Création du contexte graphique (GC) avec vérification d'erreur
    mov rdi, qword[display_name]
    test rdi, rdi                ; Vérifie que display n'est pas NULL
    jz closeDisplay

    mov rsi, qword[window]
    test rsi, rsi                ; Vérifie que window n'est pas NULL
    jz closeDisplay

    xor rdx, rdx                 ; Aucun masque particulier
    xor rcx, rcx                 ; Aucune valeur particulière
    call XCreateGC               ; Appel de XCreateGC pour créer le contexte graphique
    test rax, rax                ; Vérifie la création du GC
    jz closeDisplay              ; Si échec, quitte
    mov qword[gc], rax           ; Stocke le GC dans la variable gc

    mov rdi, qword[display_name]
    mov rsi, qword[gc]
    mov edx, 0x00FFFFFF
    call XSetForeground
	
boucle: ; Boucle de gestion des événements
    mov     rdi, qword[display_name]
    cmp     rdi, 0              ; Vérifie que le display est toujours valide
    je      closeDisplay        ; Si non, quitte
    mov     rsi, event          ; Passe l'adresse de la structure d'événement
    call    XNextEvent          ; Attend et récupère le prochain événement

    cmp     dword[event], ConfigureNotify ; Si l'événement est ConfigureNotify (ex: redimensionnement)
    je      dessine                       ; Passe à la phase de dessin

    cmp     dword[event], KeyPress        ; Si une touche est pressée
    je      closeDisplay                  ; Quitte le programme
    jmp     boucle                        ; Sinon, recommence la boucle

dessine:
    cmp byte[passe], 0
    je dessin
    jmp boucle
    
;#########################################
;#	DEBUT DE LA ZONE DE DESSIN	 #
;#########################################

dessin:
    call nb_triangles_alea
    ;mov rcx, [nb_tr]
    ;mov qword[nb_tr], 5

boucle_triangles:
    call couleur_aleatoire
    call generer_triangle
    call triangle_vecteurs
    call rectangle_calculer
    call sens_triangle
    call remplissage

    dec qword[nb_tr]
    cmp qword[nb_tr], 0
    jg boucle_triangles
    inc byte[passe]
    jmp flush

; ############################
; # FIN DE LA ZONE DE DESSIN #
; ############################

flush:
mov rdi,qword[display_name]
call XFlush
jmp boucle
mov rax,34
syscall

closeDisplay:
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit
	
