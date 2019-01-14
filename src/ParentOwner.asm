;#######################################################################################################
; ParentOwner by kero <xmemor>, draft 2010-07-06
; (changed: GetAsyncKeyState instead of GetKeyState)
;#######################################################################################################

.386
.model flat,stdcall
option casemap:none

inclib macro x
 include x.inc
 includelib x.lib
endm

include windows.inc
inclib  user32
inclib  kernel32
inclib  gdi32
inclib	shlwapi
inclib	comctl32

; PARENTOWNER struct
; 	hWnd        DWORD ?		; 0
; 	hWndParent 	DWORD ?		; 1
; 	ClientRect  RECT <>		; 2,3,4,5
; 	Exstyle     DWORD ?		; 6
; 	Style       DWORD ?		; 7
;   FncParam		DWORD ?		; 8
; 	hPrntOwner 	DWORD ?		; 9
;   Id					DWORD ?		; 10
;		reserve			DWORD ?   ; 11
; PARENTOWNER ends

; NewEdit
; CombolCaption
; NewCombol
; EnThWin
; NewStatic
; NewStatic2
; EnWin
; FillCombo
; UndoRedo
; FullUndo
; EnCh
; Winfo
; OwnerInfo
; StyleTrigger
; WndProc
; DlgProc2
; DlgProc

.const

idm_help		equ 0EEE0h

.data

prehelp			db "  //  Drag 'n' Drop  this  Help  window  //  Close  Help :  Right Click  //  ",13,10,13,10
help				db "  WIN  API   -   Window  Relationships :    Parent ,  Owner ,  Z-order          (2010-07-06)",0,13,10
						db 13,10,"  Usage :",13,10
						db 13,10,"  Any  control  right  click :  enable / disable",13,10
						db 13,10,"  Checkbox  <real  [child]> :  using  Real[ChildWindowFromPoint]",13,10						
						db 13,10,"  [Choose  'Window'  + set <Lock>]"
						db 13,10,"  a)  window  under  cursor  +  key  F8"
						db 13,10,"  b)  select  combobox list item  +  right click",13,10
						db 13,10,"  [Choose  'new Parent|Owner']"
						db 13,10,"  a)  window  under  cursor  +  key F9  (=> preset 'Window' position)"
						db 13,10,"  b)  select  combobox list item  +  left click",13,10
						db 13,10,"  [Combobox :  filtered  window  tree ,  via  Enum*Windows]"
						db 13,10,"  'Top-L' :  all  top-level  windows  (+ message-only)"
						db 13,10,"  'All' :  all  (+ message-only)  windows"
						db 13,10,"  'Desc.' :  all  descendants  of  'Window'"
						db 13,10,"  'Pid' :  all  windows  of  'Parent|Owner'  process"
						db 13,10,"  'Tid' :  all  windows  of  'Parent|Owner'  thread"
						db 13,10,"  'Point' :  all windows under cursor",13,10
						db 13,10,"  'M /' :  FILTERED  WINDOW  TREE  MONITOR ,  on/off",13,10
						db 13,10,"  'sWaP' +  <Lock> :  swap  'Window'  and  'Parent|Owner'"
						db 13,10,"  'P' / 'W' :  set  target  ('W' - 'Window' ,  'P' - 'Parent|Owner')",13,10
						db 13,10,"  [For  target]"
						db 13,10,"  'Pop /' :  WS_POPUP  on/off"
						db 13,10,"  'Child /' :  WS_CHILD  on/off"
						db 13,10,"  'min /' :  minimize / restore"
						db 13,10,"  'Vis / Hid' :  Visible / Hidden"
						db 13,10,"  'En / Dis' :  Enable / Disable"
						db 13,10,"  'ClipChild +/-' :  WS_CLIPCHILDREN  on/off"
						db 13,10,"  'Tool/' :  WS_EX_TOOLWINDOW  on/off"
						db 13,10,"  'App/' :  WS_EX_APPWINDOW  on/off"
						db 13,10,"  'Text' :  WM_SETTEXT  from  combo"
						db 13,10,"  'Id' :  set Id  from  combo"
						db 13,10,"  'X' :  post  WM_CLOSE"
						db 13,10,"  'Up','Down','Topmost','Notopmost','Top','Bottom':  change Z-position"
						db 13,10,"  'First','Prev','Next','Last':  set target  from  Z-siblings",13,10
						db 13,10,"  F8 + F9  +  <Close> :  exit  without  primary  parent  restoration",13,10
						db 13,10,"  [Window  stile  symbols]"
						db 13,10,"  L - WS_EX_LAYERED"
						db 13,10,"  T - WS_EX_TOPMOST"
						db 13,10,"  C - WS_CHILD"
						db 13,10,"  P - WS_POPUP"
						db 13,10,"  O - Overlapped  (not WS_CHILD + not WS_POPUP)"
						db 13,10,"  X - WS_CHILD + WS_POPUP,  forbidden :-)"
						db 13,10,"  m - mINIMIZED"
						db 13,10,"  M - Maximized"
						db 13,10,"  V - Visible"
						db 13,10,"  H - Hidden"
						db 13,10,"  D - Disabled"
						db 13,10,"  E - Enabled",13,10
						db 13,10,"  [Window  tree  symbols]"
						db 13,10,"  + - child"
						db 13,10,"  ? - Tid (child) != Tid (parent)"
						db 13,10,"  . - top-level"
						db 13,10,"  ! - Tid (top-level) == Tid (Desktop)"
						db 13,10,"  = - top  top-level  (notopmost)"
						db 13,10,"  o - message-only",13,10
						db 13,10,"  -----------"
						db 13,10,"  Init: 2006-06-06"						
						db 13,10,"  ©  kero  <xmemor>",13,10,0

;_msdn			db "MSDN -> Window Features -> Owned Windows :",13,10,13,10
;						db "  * An owned window is always above its owner in the z-order.",13,10
;						db "  * The system automatically destroys an owned window when its owner is destroyed.",13,10
;						db "  * An owned window is hidden when its owner is minimized.",13,10,13,10
;						db "... After creating an owned window, an application cannot transfer ownership of the window to another window.",13,10
;						db " << SOMETIMES  IT  ISN'T  TRUE !..>>",13,10,13,10,13,10
;						db "MSDN -> SetWindowLong Function :",13,10,13,10
;						db "... You must not call SetWindowLong with the GWL_HWNDPARENT index to change the parent of a child window.",13,10
;						db "  Instead, use the SetParent function.",13,10
;						db " << NOTHING  ABOUT  OWNER  HERE !..>>",13,10,13,10,13,10
;						db "MSDN -> SetParent Function :",13,10,13,10
;						db "... An application can use the SetParent function to set the parent window of a pop-up, overlapped, or child window.",13,10,13,10
;						db "  The new parent window and the child window must belong to the same application.",13,10
;						db " << NOT  ALWAYS ,  NOT  ALWAYS !..>>",13,10,13,10
;						db "... if hWndNewParent is NULL, you should also clear the WS_CHILD bit and set the WS_POPUP style after calling SetParent.",13,10
;						db "  Conversely, if hWndNewParent is not NULL and the window was previously a child of the desktop,",13,10
;						db "  you should clear the WS_POPUP style and set the WS_CHILD style before calling SetParent.",13,10,13,10 
;						db "  Windows 2000/XP: When you change the parent of a window, you should synchronize the UISTATE of both windows.",13,10
;						db "  For more information, see WM_CHANGEUISTATE and WM_UPDATEUISTATE.",13,10
;						db 13,10,"//  Double-click  -  continue,  right click  -  out  //",0

text     		db 13,10,13,10,"  Window    < F8 >    W",13,10,13,10
						db "      new  Parent | Owner    < F9 >    P",13,10,13,10
						db "  GetWindow  (gw_owner)",13,10,13,10
						db "  GetWindowLong  (gwl_hwndparent)",13,10,13,10
						db "  GetParent",13,10,13,10
						db "  GetAncestor  (ga_parent)",13,10,13,10
						db "  GetAncestor  (ga_root)",13,10,13,10
						db "  GetAncestor  (ga_rootowner)",13,10,13,10
						db "      GetWindow  (Owner , gw_enabledpopup)",13,10,13,10
						db "      GetLastActivePopup  (Owner)",0

hlp					db "About + Help",0
DlgName 		db "Dlg",0
DlgName2 		db "Dlg2",0
DlgName3 		db "Dlg3",0
_sbutton		db "s"
_button			db "Button",0
_edit				db "edit",0
;_static			db "static",0
_combolbox	db "combolbox",0
_HWND_MSG		db 13,10,13,10,"  HWND_MESSAGE",0
_HWND_DESK	db "HWND_DESKTOP",0
_mb         db "MsgBox",0
_Owner			db "Owner :",0
_Modal			db "Modal",0
_Modeless		db "Modeless",0
_Popup			db "WS_POPUP",0
_Overlapped	db "not  WS_POPUP",0
head				db "  hWnd            Z-ord        Styles        Class        Text        [ x, y, width * height ]        Id /hMenu        Pid        Tid        Exe",0
ft      		db 13,10,13,10,"  %8.8lX     %s%.4d     %s     '%s'     '%s'      [ %d , %d , %d * %d ]      id_%lu_%4.4lX    pid_%lu    tid_%lu    %s",0
ft1					db "%10.8lX  _  %s  Dialog  Box  %d",0
ft2					db "%10.8lX  _  Window  %d",0
ft3					db "%s  %8.8lX    '%s'     '%s'",0
ft4					db "%8.8lX  %s %s %s      ""%s""",0
ft5					db "%s%s",0
ft6					db "P :  _id_%lu  %s",0
ft7					db "%lu   o%lu",0
combolcap		db "  // Caption right click :  monitor  on/off",0
filter0			db "Top-level",0
filter1     db "All",0
filter4     db "W :  Descendants",0
filter5     db "Cursor over window",0
timerid			dd 1234

.data?

hinst				HINSTANCE ?
hdlg				HWND ?
hDesktop		HWND ?
hMessage		HWND ?
hw_2001			HWND ?
hw_2002			HWND ?
hw_combo	 	HWND ?
hw_combol 	HWND ?
hW					HWND ?
hP					HWND ?
hX					HWND ?
hrgn				HRGN ?
pid					dd ?
tid					dd ?
OldWndProc	dd ?
lp					dd ?
lp2					dd ?
create_count	dd ?	
win_count		dd ?
lck					dd ?
mon					dd ?
filter			dd ?
MinDlgWidth	dd ?
DlgHeight		dd ?
staticX			dd ?
staticY			dd ?
staticW			dd ?
staticH			dd ?
topwin			dd ?
point				POINT <>
styles			db 8 dup(?)
stylesP			db 8 dup(?)
buff0				db 2048 dup(?)
buff				db 2048 dup(?)
undo_stack	dd 12*64 dup(?)

.code

;#######################################################################################################

NewEdit proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

	.if uMsg==WM_RBUTTONUP
		invoke DestroyWindow,hWnd

	.elseif uMsg==WM_LBUTTONDOWN
		invoke DefWindowProc,hWnd,WM_NCLBUTTONDOWN,HTCAPTION,lParam

	.else
		invoke GetWindowLong,hWnd,GWL_USERDATA
		invoke CallWindowProc,eax,hWnd,uMsg,wParam,lParam
		ret
	.endif
	mov eax,FALSE
	ret
NewEdit endp

;#######################################################################################################

CombolCaption proc
	local buf[256]:BYTE

	.if filter==0 ; || filter==6
		mov eax,offset filter0
		jmp @f
	.elseif filter==1
		mov eax,offset filter1
		jmp @f
	.elseif filter==4
		mov eax,offset filter4
		jmp @f
	.elseif filter==5
		mov eax,offset filter5
@@:
		invoke wsprintf, addr buf,offset ft5,eax,offset combolcap
	.elseif filter==2
		mov al,'p'
		mov ecx,pid
		jmp @f
	.elseif filter==3
		mov al,'t'
		mov ecx,tid
@@:
		mov byte ptr [ft6+5],al
		invoke wsprintf,addr buf,offset ft6,ecx,offset combolcap
	.endif
	invoke SendMessage,hw_combol,WM_SETTEXT,0,addr buf
	ret
CombolCaption endp

;#######################################################################################################

NewCombol proc uses ebx hWnd:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	local buf[64]:BYTE
	local rt:RECT

	.if uMsg==WM_CLOSE
		mov eax,FALSE
		ret

	.elseif uMsg==WM_RBUTTONDOWN
		invoke SendMessage,hWnd,LB_ITEMFROMPOINT,0,lParam
		mov ebx,eax
		invoke SendMessage,hWnd,LB_SETCURSEL,ebx,0
		invoke SendMessage,hWnd,LB_GETITEMDATA,ebx,0
		mov hW,eax
		mov lck,1
		invoke SendDlgItemMessage,hdlg,2000,BM_SETCHECK,1,0

	.elseif uMsg==WM_NCRBUTTONDOWN && wParam==HTCAPTION
		.if mon!=0
			mov mon,0
		.else
			invoke GetWindowRect,hWnd,addr rt
			mov eax,rt.bottom
			sub eax,rt.top
			mov mon,eax
		.endif
		invoke InvalidateRect,hWnd,0,1

	.elseif uMsg==WM_WINDOWPOSCHANGING
		.if mon!=0
			mov eax,lParam
			mov ecx,mon
			mov dword ptr [eax+5*4],ecx
			xor eax,eax
			ret
		.endif

	.endif
	invoke GetWindowLong,hWnd,GWL_USERDATA
	invoke CallWindowProc,eax,hWnd,uMsg,wParam,lParam
	ret
NewCombol endp

;#######################################################################################################

NewStatic proc hWnd:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	local rt:RECT

	.if uMsg==WM_LBUTTONDOWN
		invoke DefWindowProc,hWnd,WM_NCLBUTTONDOWN,HTCAPTION,lParam

	.elseif uMsg==WM_LBUTTONDBLCLK
		invoke SetWindowPos,hWnd,0,staticX,staticY,0,0,SWP_NOZORDER OR SWP_NOSIZE OR SWP_FRAMECHANGED

	.elseif uMsg==WM_WINDOWPOSCHANGING
		mov eax,lParam
		mov ecx,hw_2002
		mov dword ptr [eax+4],ecx
		mov edx,dword ptr [eax+2*4]
		mov ecx,staticX
		cmp edx,ecx
		jl @f
		mov dword ptr [eax+2*4],ecx
@@:
		mov ecx,staticY
		mov dword ptr [eax+3*4],ecx
		mov ecx,staticW
		mov dword ptr [eax+4*4],ecx
		mov ecx,staticH
		mov dword ptr [eax+5*4],ecx

	.else
		invoke GetWindowLong,hWnd,GWL_USERDATA
		invoke CallWindowProc,eax,hWnd,uMsg,wParam,lParam
		ret
	.endif
	mov eax,FALSE
	ret
NewStatic endp

;#######################################################################################################

NewStatic2 proc hWnd:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	.if uMsg==WM_LBUTTONDOWN
		invoke SendMessage,hdlg,WM_LBUTTONDOWN,wParam,lParam
	.endif
	invoke GetWindowLong,hWnd,GWL_USERDATA
	invoke CallWindowProc,eax,hWnd,uMsg,wParam,lParam
	ret
NewStatic2 endp

;#######################################################################################################

EnThWin proc hWnd:HWND,param:DWORD
	local buf[64]:BYTE
	invoke GetClassName,hWnd,addr buf,63
	invoke lstrcmpi,addr buf,offset _combolbox
	.if eax==0
		mov ecx,hWnd
		mov hw_combol,ecx
	.endif
	ret
EnThWin endp

;#######################################################################################################

EnWin proc uses ebx edi esi hWnd:HWND,param:DWORD
	local buf0[256]:BYTE
	local buf[256]:BYTE
	local buf1[64]:BYTE
	local buf2[64]:BYTE
	local buf3[64]:BYTE
	local buf4[2]:BYTE
	local lpid:DWORD
	local pt:POINT
	local rt:RECT

	mov word ptr [buf4],[0][' ']

	.if hWnd==HWND_DESKTOP
		mov edx,hDesktop
		mov ecx,offset _HWND_DESK
		jmp @f
	.elseif hWnd==HWND_MESSAGE
		mov edx,hMessage
		mov ecx,offset _HWND_MSG+6
@@:
		invoke lstrcpy,addr buf,ecx
	.else
		mov edx,hWnd
	.endif
	invoke GetWindowThreadProcessId,edx,addr lpid
	mov edi,eax																				; ltid
	xor esi,esi
	mov eax,hWnd
	lea ebx,buf1
	mov byte ptr [ebx],0
	.if eax==HWND_DESKTOP || eax==HWND_MESSAGE
		jmp @f
	.elseif eax==hDesktop || eax==hMessage
	.else
		.while (eax!=hDesktop && eax!=hMessage)
			mov byte ptr [ebx],'+'												; window tree
			inc ebx
			inc esi
			invoke GetAncestor,eax,GA_PARENT 
		.endw
		mov	byte ptr [ebx],[0]
		invoke GetAncestor,hWnd,GA_PARENT 
		invoke GetWindowThreadProcessId,eax,0
		.if eax==edi && esi==1
			mov al,'!'
		.elseif eax!=edi && esi==1
			mov al,'.'
		.elseif eax!=edi && esi!=1
			mov al,'?'
		.elseif eax==edi && esi!=1
			mov al,' '
		.endif
		mov byte ptr [buf1],al
	.endif

	.if esi==1 && topwin==0
		invoke GetWindowLong,hWnd,GWL_EXSTYLE
		and eax,WS_EX_TOPMOST
		.if eax==0
			inc topwin
			mov byte ptr [buf4],'='
		.endif
	.endif

	invoke GetClassName,hWnd,addr buf2,63
	invoke SendMessageTimeout,hWnd,WM_GETTEXT,63,addr buf3,SMTO_ABORTIFHUNG,200,0
	invoke wsprintf,addr buf,addr ft4,hWnd,addr buf4,addr buf1,addr buf2,addr buf3
@@:
	mov eax,lpid
	.if filter==0 && esi>1														; all top-level windows (+ message-only)
		jmp @f
	.elseif filter==5             										; all following windows: cursor over WindowRect
		invoke GetCursorPos,addr pt
		invoke GetWindowRect,hWnd,addr rt
		invoke PtInRect,addr rt,pt.x,pt.y
		test eax,eax
		jz @f
		invoke GetWindowRgn,hWnd,hrgn
		.if eax==NULLREGION
			jmp @f

		.elseif eax==SIMPLEREGION || eax==COMPLEXREGION
			mov eax,pt.x
			sub eax,rt.left
			mov ecx,pt.y
			sub ecx,rt.top
			invoke PtInRegion,hrgn,eax,ecx
			.if eax==0
				jmp @f
			.endif
		.endif

	.elseif filter==1             										; all windows (+ message-only)
	.elseif filter==4		              								; all descendants
	.elseif filter==2 && eax!=pid											; all PID(hP)-windows (+ message-only)
		jmp @f
	.elseif filter==3 && edi!=tid											; all TID(hP)-windows (+ message-only)
		jmp @f
	.endif
	mov ebx,win_count
	inc win_count
	.if param==0
		invoke SendMessage,hw_combo,CB_GETLBTEXT,ebx,addr buf0
		invoke lstrcmp,addr buf0,addr buf
		.if eax!=0
			xor eax,eax
			mov win_count,eax
			ret
		.else
			inc eax
			ret
		.endif
	.else
		invoke SendMessage,hw_combo,CB_ADDSTRING,0,addr buf
		invoke SendMessage,hw_combo,CB_SETITEMDATA,ebx,hWnd
		mov eax,hWnd
		.if eax==hP
			invoke SendMessage,hw_combo,CB_SETCURSEL,ebx,0
		.endif
	.endif
@@:
	xor eax,eax
	inc eax
	ret
EnWin endp

;#######################################################################################################

FillCombo proc uses ebx
	local buf[64]:BYTE
	local buf2[64]:BYTE

	.if hP==HWND_DESKTOP
		mov ecx,hDesktop
	.elseif hP==HWND_MESSAGE
		mov ecx,hMessage
	.else
		mov ecx,hP
	.endif
	invoke GetWindowThreadProcessId,ecx,addr pid
	mov tid,eax
	mov win_count,0

	.if filter==4
		mov lck,1
		invoke SendDlgItemMessage,hdlg,2000,BM_SETCHECK,1,0

		invoke EnWin,hW,0
		invoke EnumChildWindows,hW,addr EnWin,0
		mov eax,win_count
		test eax,eax
		jz @f
		ret
@@:
		invoke SendMessage,hw_combo,CB_RESETCONTENT,0,0
		invoke EnWin,hW,1
		invoke EnumChildWindows,hW,addr EnWin,1
		mov ebx,win_count

;	.elseif filter==6
;		invoke SendMessage,hw_combo,CB_RESETCONTENT,0,0
;		mov topwin,0
;		invoke EnWin,HWND_DESKTOP,1
;		invoke EnWin,hDesktop,1
;		invoke GetWindow,hDesktop,GW_CHILD
;		mov ebx,eax
;@@:
;		invoke EnWin,ebx,1
;		invoke GetWindow,ebx,GW_HWNDNEXT
;		mov ebx,eax
;		test eax,eax
;		jnz @b
;		invoke EnWin,HWND_MESSAGE,1
;		invoke EnWin,hMessage,1
;		invoke GetWindow,hMessage,GW_CHILD
;		mov ebx,eax
;@@:
;		invoke EnWin,ebx,1
;		invoke GetWindow,ebx,GW_HWNDNEXT
;		mov ebx,eax
;		test eax,eax
;		jnz @b

	.else
		mov topwin,0
		invoke EnWin,HWND_DESKTOP,0
		invoke EnWin,hDesktop,0
		invoke EnumChildWindows,hDesktop,addr EnWin,0
		mov eax,win_count
		test eax,eax
		jz @f
		invoke EnWin,HWND_MESSAGE,0
		invoke EnWin,hMessage,0
		invoke EnumChildWindows,hMessage,addr EnWin,0
		mov eax,win_count
		test eax,eax
		jz @f
		ret
@@:
		mov topwin,0
		invoke SendMessage,hw_combo,CB_RESETCONTENT,0,0
		invoke EnWin,HWND_DESKTOP,1
		invoke EnWin,hDesktop,1
		invoke EnumChildWindows,hDesktop,addr EnWin,1
		mov ebx,win_count
		invoke EnWin,HWND_MESSAGE,1
		invoke EnWin,hMessage,1
		invoke EnumChildWindows,hMessage,addr EnWin,1
	.endif

	.if filter==4
		invoke wsprintf,addr buf,offset ft7+7,ebx
	.else
		mov ecx,win_count
		sub ecx,ebx
		invoke wsprintf,addr buf,offset ft7,ebx,ecx
	.endif

	invoke GetDlgItemText,hdlg,2026,addr buf2,63
	invoke lstrcmp,addr buf,addr buf2
	.if eax!=0
		invoke SetDlgItemText,hdlg,2026,addr buf
	.endif
	ret
FillCombo endp

;#######################################################################################################

UndoRedo proc uses ebx edi esi param:DWORD
	local rt:RECT
	local hparent:HWND
	local style:DWORD
	local exstyle:DWORD
	local retval:DWORD
	local id:DWORD

	mov eax,param
	sub lp,eax
	mov ebx,lp
	mov eax,ebx
	shl ebx,1
	add ebx,eax
	shl ebx,4																		; lp*4*4*3  
	add ebx,offset undo_stack

	mov edi,dword ptr [ebx]											; ? hW
	mov esi,dword ptr [ebx+9*4]									; ? hPO

	invoke GetWindowLong,edi,GWL_ID
	mov id,eax
	invoke GetWindowLong,edi,GWL_EXSTYLE
	mov exstyle,eax
	invoke GetWindowLong,edi,GWL_STYLE
	mov style,eax
	invoke GetAncestor,edi,GA_PARENT
	mov hparent,eax
	invoke GetWindowRect,edi,addr rt
	invoke MapWindowPoints,0,hparent,addr rt,2

	mov eax,dword ptr [ebx+8*4]
	.if eax==0
		invoke SetParent,edi,esi
		test eax,eax
		jnz @f
	.else
		invoke SetLastError,0
		invoke SetWindowLong,edi,GWL_HWNDPARENT,esi
		test eax,eax
		jnz @f
		invoke GetLastError
		test eax,eax
		jz @f
	.endif
	jmp @err
@@:
	mov retval,eax

	invoke GetAncestor,edi,GA_PARENT

	mov ecx,dword ptr [ebx+4]										; ? hP
	.if ecx==0
		mov ecx,hDesktop
	.endif

	.if eax!=ecx
		mov eax,dword ptr [ebx+8*4]
		.if eax==0
			invoke SetParent,edi,retval
		.else
			invoke SetWindowLong,edi,GWL_HWNDPARENT,retval
		.endif
@err:
		invoke MessageBeep,MB_ICONHAND
		jmp @@@
	.endif

	mov hW,edi

	mov eax,hparent
	mov dword ptr [ebx+4],eax
	mov hparent,ecx

	mov eax,dword ptr [ebx+6*4]
	invoke SetWindowLong,hW,GWL_EXSTYLE,eax
	mov eax,exstyle
	mov dword ptr [ebx+6*4],eax

	mov eax,dword ptr [ebx+7*4]
	invoke SetWindowLong,hW,GWL_STYLE,eax
	mov eax,style
	mov dword ptr [ebx+7*4],eax

	mov eax,retval
	mov dword ptr [ebx+9*4],eax

	mov eax,dword ptr [ebx+10*4]
	invoke SetWindowLong,hW,GWL_ID,eax
	mov eax,id
	mov dword ptr [ebx+10*4],eax

	push SWP_NOZORDER OR SWP_FRAMECHANGED
	mov eax,dword ptr [ebx+5*4]
	mov ecx,dword ptr [ebx+3*4]
	sub eax,ecx
	push eax
	mov eax,dword ptr [ebx+4*4]
	mov edx,dword ptr [ebx+2*4]
	sub eax,edx
	push eax
	push ecx
	push edx
	push 0
	push edi
	call SetWindowPos

	mov eax,rt.left
	mov dword ptr [ebx +2*4],eax
	mov eax,rt.top
	mov dword ptr [ebx +3*4],eax
	mov eax,rt.right
	mov dword ptr [ebx +4*4],eax
	mov eax,rt.bottom
	mov dword ptr [ebx +5*4],eax

;	invoke InvalidateRect,hW,0,1
;	invoke RedrawWindow,hW,0,0,RDW_ERASE OR RDW_INVALIDATE OR RDW_ALLCHILDREN

	invoke IsWindowVisible,hW
	.if eax!=0
		invoke ShowWindow,hW,SW_HIDE
		invoke ShowWindow,hW,SW_SHOWNORMAL
	.endif

@@@:
	mov eax,param
	dec eax
	sub lp,eax
	invoke SetDlgItemInt,hdlg,2006,lp,0
	ret
UndoRedo endp

;#######################################################################################################

FullUndo proc
	.while lp>0
		invoke UndoRedo,1	; Undo
	.endw
	xor eax,eax
	mov lp2,eax
	ret
FullUndo endp

;#######################################################################################################

EnCh proc hWnd:HWND, param:DWORD
	inc win_count
	mov ecx,hWnd
	xor eax,eax
	.if ecx!=param
		inc eax
	.endif
	ret
EnCh endp

;#######################################################################################################

Winfo proc uses ebx edi esi hWnd:HWND,lpbuff:DWORD
	local buf[512]:BYTE
	local buf1[64]:BYTE
	local buf2[64]:BYTE
	local buf3[64]:BYTE
	local mo[2]:BYTE
	local rt:RECT
	local pe32:PROCESSENTRY32
	local pid_:DWORD
	local tid_:DWORD
	local id_:DWORD
	local idd[32]:BYTE

	mov byte ptr [idd],0
	mov esi,hWnd
	invoke IsWindow,hWnd
	.if esi==HWND_MESSAGE
		invoke lstrcpy,addr buf,offset _HWND_MSG
		jmp @0
	.elseif eax==0 || esi==0
		xor esi,esi
		mov dword ptr [buf],0a0d0a0dh	;	13,10,13,10
		mov dword ptr [buf+4],[0]['0  ']
		jmp @0
	.endif
	xor eax,eax
	mov dword ptr[buf1],eax
	mov dword ptr[buf2],eax
	mov dword ptr[buf],eax
	mov ebx,offset styles
	mov	dword ptr [ebx],'___ '
	mov	dword ptr [ebx+4],[0]['-__']
	mov win_count,eax

	invoke GetAncestor,hWnd,GA_ROOT
	invoke GetAncestor,eax,GA_PARENT
	mov ecx,hDesktop
	mov edx,hMessage

	.if hWnd==ecx || eax==ecx
		mov word ptr [mo],[0][' ']
	.elseif hWnd==edx || eax==edx
		mov word ptr [mo],[0]['o']
	.endif

	.if hWnd!=ecx && hWnd!=edx
		invoke EnumChildWindows,eax,addr EnCh,hWnd
	.endif

	invoke GetClassName,hWnd,addr buf1,63
	invoke SendMessageTimeout,hWnd,WM_GETTEXT,63,addr buf2,SMTO_ABORTIFHUNG,100,0
	lea ecx,buf2
@@:
	mov al,byte ptr[ecx]
	test al,al
	jz @f
	.if al==13 || al==10
		mov byte ptr[ecx],32
	.endif
	inc ecx
	jmp @b
@@:
	invoke GetWindowLong,hWnd,GWL_ID
	mov id_,eax


	invoke GetWindowLong,hWnd,GWL_EXSTYLE
	push eax
	and eax,WS_EX_LAYERED
	.if eax!=0
		mov	byte ptr [ebx],'L'		  ; layered
	.endif
	pop eax
	and eax,WS_EX_TOPMOST
	.if eax!=0
		mov	byte ptr [ebx+1],'T'		; topmost
	.endif
	
	
	
	invoke GetWindowLong,hWnd,GWL_STYLE
	push eax
	mov ecx,eax
	and eax,WS_POPUP
	and ecx,WS_CHILD
	.if eax!=0 && ecx!=0
		mov	al,'X'									; WS_POPUP + WS_CHILD  ("impossible" case)
	.elseif eax!=0 && ecx==0
		mov	al,'P'									; WS_POPUP
	.elseif eax==0 && ecx!=0
		mov	al,'C'									; WS_CHILD
	.elseif eax==0 && ecx==0
		mov	al,'O'									; WS_OVERLAPPED (quasi!)
	.endif
	mov	byte ptr [ebx+2],al
	pop eax
	and eax,WS_CLIPCHILDREN				; WS_CLIPCHILDREN
	.if eax!=0
		mov	byte ptr [ebx+6],'+'
	.endif
	invoke IsIconic,hWnd
	.if eax!=0
		mov	byte ptr [ebx+3],'m'		; minimized
	.endif
	invoke IsZoomed,hWnd
	.if eax!=0
		mov	byte ptr [ebx+3],'M'		; maximized
	.endif
	invoke IsWindowVisible,hWnd
	.if eax!=0
		mov	al,'V'									; visible
	.else
		mov	al,'H'									; hidden
	.endif
	mov	byte ptr [ebx+4],al
	invoke IsWindowEnabled,hWnd
	.if eax!=0
		mov	al,'E'									; enabled
	.else
		mov	al,'D'									; disabled
	.endif
	mov	byte ptr [ebx+5],al

	invoke GetWindowThreadProcessId,hWnd,addr pid_
	mov tid_,eax
	invoke CreateToolhelp32Snapshot,TH32CS_SNAPPROCESS,pid_
	mov edi,eax    ; hSnapshot
	mov pe32.dwSize,sizeof pe32 
	invoke Process32First,edi,addr pe32 
@@:
	test eax,eax
	jz @err
	mov eax,pid_
	cmp pe32.th32ProcessID,eax
	jz @f
	invoke Process32Next,edi,addr pe32
	jmp @b
@@:
	invoke CloseHandle,edi

  lea eax,pe32.szExeFile
  mov byte ptr[eax+63],0
	invoke lstrcpy,addr buf3,eax

	invoke PathStripPath,eax
	jmp @f
@err:
	mov word ptr [buf3],[0]['?']			; "?",0
@@:
	invoke GetWindowRect,hWnd,addr rt
	mov ecx,rt.right
	sub ecx,rt.left
	mov edx,rt.bottom
	sub edx,rt.top
	mov ebx,id_
	and ebx,0ffffh
	invoke wsprintf,addr buf,offset ft,hWnd,addr mo,win_count,addr styles,addr buf1,addr buf2,rt.left,rt.top,ecx,edx,ebx,ebx,pid_,tid_,addr buf3
@0:
	invoke lstrcat,lpbuff,addr buf
	mov eax,esi
	ret
Winfo endp

;#######################################################################################################

OwnerInfo proc uses ebx hWnd:HWND
	local buf[256]:BYTE
	local buf1[64]:BYTE
	local buf2[64]:BYTE

	invoke GetWindow,hWnd,GW_OWNER
	mov ebx,eax
	.if ebx!=0
		invoke GetClassName,ebx,addr buf1,63
		invoke SendMessageTimeout,ebx,WM_GETTEXT,63,addr buf2,SMTO_ABORTIFHUNG,100,0
		invoke wsprintf,addr buf,offset ft3,offset _Owner,ebx,addr buf1,addr buf2
	.else
		invoke lstrcpy,addr buf,offset _Owner
	.endif
	invoke SendDlgItemMessage,hWnd,201,WM_SETTEXT,0,addr buf
	ret
OwnerInfo endp

;#######################################################################################################

StyleTrigger proc hWnd:HWND,style:DWORD  ; (style - one bit only)
	invoke GetWindowLong,hWnd,GWL_STYLE
  xor eax,style
	invoke SetWindowLong,hWnd,GWL_STYLE,eax
	invoke SetWindowPos,hWnd,0,0,0,0,0,SWP_NOZORDER OR SWP_NOMOVE OR SWP_NOSIZE OR SWP_FRAMECHANGED
	invoke InvalidateRect,hWnd,0,1
	ret
StyleTrigger endp

;#######################################################################################################

WndProc proc hWnd:HWND,uMsg:UINT,wParam:WPARAM, lParam:LPARAM
	local buf[64]:BYTE

	.if uMsg==WM_CREATE
		mov eax,hWnd
		mov hW,eax
		mov lck,1
		invoke SendDlgItemMessage,hdlg,2000,BM_SETCHECK,1,0
		inc create_count
		invoke wsprintf,addr buf,offset ft2,hWnd,create_count
		invoke SendMessage,hWnd,WM_SETTEXT,0,addr buf

	.elseif uMsg==WM_WINDOWPOSCHANGED
		invoke OwnerInfo,hWnd

	.elseif uMsg==WM_LBUTTONDOWN
		invoke DefWindowProc,hWnd,WM_NCLBUTTONDOWN,HTCAPTION,lParam

	.elseif uMsg==WM_COMMAND && wParam==202
		invoke StyleTrigger,hWnd,WS_POPUP

	.elseif uMsg==WM_STYLECHANGED
		invoke GetWindowLong,hWnd,GWL_STYLE
		mov ecx,offset _Overlapped
		test eax,WS_POPUP
		jz @f
		mov ecx,offset _Popup
@@:
		invoke SendDlgItemMessage,hWnd,202,WM_SETTEXT,0,ecx

	.else
		invoke CallWindowProc,OldWndProc,hWnd,uMsg,wParam,lParam
		ret

	.endif
	mov eax,FALSE
	ret
WndProc endp

;#######################################################################################################

DlgProc2 proc hWnd:HWND,uMsg:UINT,wParam:WPARAM, lParam:LPARAM
	local buf[64]:BYTE

	.if uMsg==WM_INITDIALOG
		mov eax,hWnd
		mov hW,eax
		mov lck,1
		invoke SendDlgItemMessage,hdlg,2000,BM_SETCHECK,1,0
		inc create_count
		invoke SetWindowLong,hWnd,GWL_USERDATA,lParam
		.if lParam==0
			mov edx,offset _Modal
		.else
			mov edx,offset _Modeless
		.endif
		invoke wsprintf,addr buf,offset ft1,hWnd,edx,create_count
		invoke SendMessage,hWnd,WM_SETTEXT,0,addr buf
		jmp @f

	.elseif uMsg==WM_WINDOWPOSCHANGED
@@:
		invoke OwnerInfo,hWnd

	.elseif uMsg==WM_CLOSE
		invoke GetWindowLong,hWnd,GWL_USERDATA
		.if eax==0
			invoke EndDialog,hWnd,0
		.else
			invoke DestroyWindow,hWnd
		.endif

	.elseif uMsg==WM_LBUTTONDOWN
		invoke DefWindowProc,hWnd,WM_NCLBUTTONDOWN,HTCAPTION,lParam

	.elseif uMsg==WM_COMMAND && wParam==202
		invoke StyleTrigger,hWnd,WS_POPUP

	.elseif uMsg==WM_STYLECHANGED
		invoke GetWindowLong,hWnd,GWL_STYLE
		mov ecx,offset _Overlapped
		test eax,WS_POPUP
		jz @f
		mov ecx,offset _Popup
@@:
		invoke SendDlgItemMessage,hWnd,202,WM_SETTEXT,0,ecx

	.else
		mov eax,FALSE
		ret

	.endif
	mov eax,TRUE
	ret
DlgProc2 endp

;#######################################################################################################

DlgProc proc uses ebx edi esi hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

	local pt:POINT
	local rt:RECT
	local wc:WNDCLASSEX
	local buf[256]:BYTE
	local buf1[64]:BYTE
;	local cbi:COMBOBOXINFO
	local style:DWORD
	local exstyle:DWORD
	local id:DWORD
	local cid:DWORD

	mov eax,uMsg
	mov edx,lParam

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.if eax==WM_CLOSE

		invoke GetAsyncKeyState,VK_F8
		and eax,8000h
		mov ebx,eax
		invoke GetAsyncKeyState,VK_F9
		and eax,8000h
		.if eax==0 || ebx==0
			invoke FullUndo
		.endif
		invoke KillTimer,hWnd,timerid
		invoke DeleteObject,hrgn
		invoke EndDialog,hWnd,0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;	.elseif eax==WM_NCHITTEST
;		invoke DefWindowProc,hWnd,uMsg,wParam,lParam
;		.if eax!=HTTOP && eax!=HTBOTTOM
;			xor eax,eax
;			jmp @ret
;		.endif

	.elseif eax==WM_SETCURSOR && (dx==HTTOP || dx==HTBOTTOM)
		mov eax,32512
		jmp @f
	.elseif eax==WM_SETCURSOR && (dx==HTTOPLEFT || dx==HTTOPRIGHT || dx==HTBOTTOMLEFT || dx==HTBOTTOMRIGHT)
		mov eax,32644
@@:
		invoke LoadCursor,0,eax
		invoke SetCursor,eax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;	.elseif eax==WM_ACTIVATE

;		invoke GetDlgItem,hWnd,2000
;		invoke SetFocus,eax
;		mov eax,FALSE
;		jmp @ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.elseif eax==WM_INITDIALOG

		push hWnd
		pop hdlg
		xor eax,eax
		mov dword ptr[buff0],eax
		mov hW,eax
		mov hP,eax

		invoke SendDlgItemMessage,hWnd,2002,WM_SETTEXT,0,offset text
		invoke SendMessage,hWnd,WM_SETTEXT,0,offset help
		invoke lstrlen,offset help
		mov byte ptr[help+eax],' '

		invoke GetDlgItem,hWnd,2001
		mov hw_2001,eax
		invoke SetWindowLong,hw_2001,GWL_WNDPROC,offset NewStatic
		invoke SetWindowLong,hw_2001,GWL_USERDATA,eax

		invoke GetDlgItem,hWnd,2002
		mov hw_2002,eax
		invoke SetWindowLong,hw_2002,GWL_WNDPROC,offset NewStatic2
		invoke SetWindowLong,hw_2002,GWL_USERDATA,eax

		invoke GetDlgItem,hdlg,2016
		mov hw_combo,eax
;			mov cbi.cbSize,sizeof cbi
;			invoke GetComboBoxInfo,hw_combo,addr cbi
;			push cbi.hwndList
;			pop hw_combol
		invoke GetWindowThreadProcessId,hWnd,0
		invoke EnumThreadWindows,eax,offset EnThWin,0
		invoke SetWindowLong,hw_combol,GWL_WNDPROC,offset NewCombol
		invoke SetWindowLong,hw_combol,GWL_USERDATA,eax
		invoke SetWindowPos,hw_combol,HWND_TOPMOST,0,0,0,0,SWP_NOSIZE OR SWP_NOMOVE OR SWP_FRAMECHANGED
		invoke SetWindowLong,hw_combol,GWL_HWNDPARENT,hWnd
		invoke CombolCaption

		invoke GetWindowRect,hWnd,addr rt
		mov eax,rt.right
		sub eax,rt.left
		mov MinDlgWidth,eax
		mov eax,rt.bottom
		sub eax,rt.top
		mov DlgHeight,eax

		invoke GetWindowRect,hw_2001,addr rt
		invoke MapWindowPoints,0,hWnd,addr rt,2
		mov eax,rt.top
		mov staticY,eax
		mov eax,rt.left
		mov staticX,eax
		mov eax,rt.bottom
		sub eax,rt.top
		mov staticH,eax
		invoke GetSystemMetrics,SM_CXSCREEN
		add eax,eax
		mov staticW,eax
		invoke SetWindowPos,hw_2001,0,0,0,staticW,staticH,SWP_NOZORDER OR SWP_NOMOVE OR SWP_FRAMECHANGED

		invoke GetSystemMenu,hWnd,0
		mov ebx,eax
		invoke AppendMenu,ebx,MF_SEPARATOR,0,0
		invoke AppendMenu,ebx,MF_STRING,idm_help,offset hlp

		mov wc.cbSize,sizeof WNDCLASSEX
		invoke GetClassInfoEx,0,offset _button,addr wc
		mov wc.style,CS_DBLCLKS
		mov eax,wc.lpfnWndProc
		mov OldWndProc,eax
		mov wc.lpfnWndProc, offset WndProc
;		mov wc.cbClsExtra,0
		mov wc.cbWndExtra,DLGWINDOWEXTRA
		mov eax,hinst
		mov wc.hInstance,eax
;		mov wc.hIcon,0
;		mov wc.hCursor,0
;		mov wc.hbrBackground,0
;		mov wc.lpszMenuName,0
		mov wc.lpszClassName,offset _sbutton
;		mov wc.hIconSm,0
		invoke RegisterClassEx,addr wc

		invoke GetDesktopWindow
		mov hDesktop,eax

;------------ anti HideToolz by Ms-Rem -------------

		invoke SetParent,hWnd,HWND_MESSAGE  ;  
		invoke GetAncestor,hWnd,GA_PARENT
		mov hMessage,eax
		invoke SetParent,hWnd,0

;             instead of
;
;		invoke FindWindowEx,HWND_MESSAGE,0,0,0
;		test eax,eax
;		jz @f
;		invoke GetAncestor,eax,GA_PARENT
;@@:
;		mov hMessage,eax
;---------------------------------------------------

		invoke SendDlgItemMessage,hWnd,2007,BM_CLICK,0,0

		invoke CreateRectRgn,0,0,0,0
		mov hrgn,eax

		invoke SetTimer,hWnd,timerid,100,0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.elseif eax==WM_TIMER

		invoke IsDlgButtonChecked,hWnd,2038													;  set hX=hW or hX=hP
		.if eax!=0
			mov ecx,hW
			mov hX,ecx
			mov word ptr [buf1],[0]['W']
		.else
			mov ecx,hP
			mov hX,ecx
			mov word ptr [buf1],[0]['P']
		.endif
		mov bx,word ptr [buf1]
		invoke SendDlgItemMessage,hWnd,2038,WM_GETTEXT,63,addr buf1
		mov ax,word ptr [buf1]
		.if ax!=bx
			mov word ptr [buf1],bx
			invoke SendDlgItemMessage,hWnd,2038,WM_SETTEXT,0,addr buf1
		.endif

		invoke lstrcpy,addr buff,addr head
		lea edi,buff

		.if lck==0
			invoke GetCursorPos,addr pt
		  invoke IsDlgButtonChecked,hWnd,200  ; real <child...>
		  mov esi,eax
;;		invoke WindowFromPoint,pt.x,pt.y
;			invoke GetDesktopWindow
			mov ebx,hDesktop
			mov ecx,ebx
@@:
			invoke MapWindowPoints,ecx,ebx,addr pt,1
      .if esi==0
        invoke ChildWindowFromPointEx,ebx,pt.x,pt.y,CWP_SKIPINVISIBLE  ; CWP_ALL
      .else
        invoke RealChildWindowFromPoint,ebx,pt.x,pt.y
      .endif
			.if eax!=0 && eax!=ebx
				mov ecx,ebx
				mov ebx,eax
				jmp @b
			.endif

			invoke GetAsyncKeyState,VK_F8
			and ax,8000h
			.if ax!=0
				mov lck,eax
				invoke SendDlgItemMessage,hWnd,2000,BM_SETCHECK,eax,0
				mov hW,ebx
			.endif

			invoke GetAsyncKeyState,VK_F9
			and ax,8000h
			.if ax!=0
				mov hP,ebx
				invoke GetCursorPos,addr point
			.endif

		.else
			mov ebx,hW
		.endif

		invoke Winfo,ebx,edi

		invoke Winfo,hP,edi
		mov hP,eax

		mov eax,dword ptr[styles]
		mov dword ptr[stylesP],eax
		mov eax,dword ptr[styles+4]
		mov dword ptr[stylesP+4],eax

		invoke GetWindow,ebx,GW_OWNER
		invoke Winfo,eax,edi

		invoke GetWindowLong,ebx,GWL_HWNDPARENT
		invoke Winfo,eax,edi

		invoke GetParent,ebx
		invoke Winfo,eax,edi

		invoke GetAncestor,ebx,GA_PARENT
		invoke Winfo,eax,edi

		invoke GetAncestor,ebx,GA_ROOT
		invoke Winfo,eax,edi

		invoke GetAncestor,ebx,GA_ROOTOWNER
		invoke Winfo,eax,edi

		invoke GetWindow,hP,GW_ENABLEDPOPUP
		.if eax==hP
			xor eax,eax
		.endif
		invoke Winfo,eax,edi

		invoke GetLastActivePopup,hP
		.if eax==hP
			xor eax,eax
		.endif
		invoke Winfo,eax,edi

		invoke lstrcmp,addr buff0,edi
		.if eax!=0
			invoke lstrcpy,addr buff0,edi
			invoke SendDlgItemMessage,hWnd,2001,WM_SETTEXT,0,edi
		.endif

		invoke IsWindowVisible,hw_combol
		.if eax==0
			mov mon,eax
			invoke GetWindowLong,hw_combol,GWL_STYLE
			mov ecx,eax
			and eax,not (WS_CAPTION or WS_THICKFRAME or WS_POPUP)
			or eax,WS_BORDER
			.if eax!=ecx
				invoke SetWindowLong,hw_combol,GWL_STYLE,eax
				invoke SetWindowPos,hw_combol,0,0,0,0,0,SWP_NOZORDER OR SWP_NOMOVE OR SWP_NOSIZE OR SWP_FRAMECHANGED
			.endif
		.else
			.if mon!=0
				invoke FillCombo
			.endif
		.endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.elseif eax==WM_SYSCOMMAND && wParam==idm_help

		invoke GetClientRect,hw_2001,addr rt
		invoke MapWindowPoints,hw_2001,0,addr rt,1
		mov ecx,rt.bottom
		mov edx,ecx
		shr ecx,2
		mov eax,ecx
		shr eax,3
		add rt.top,ecx
		add rt.left,eax
		sub edx,ecx
		sub edx,eax
		mov ecx,edx
		add edx,edx
		invoke CreateWindowEx,WS_EX_TOPMOST or WS_EX_TOOLWINDOW,\
													offset _edit,offset prehelp,\
													WS_POPUP or WS_VISIBLE or WS_VSCROLL or WS_HSCROLL or WS_THICKFRAME or ES_MULTILINE or ES_READONLY,\
													rt.left,rt.top,edx,ecx,\
													hWnd,0,hinst,0
		mov ebx,eax
		invoke SetWindowLong,ebx,GWL_WNDPROC,addr NewEdit
		invoke SetWindowLong,ebx,GWL_USERDATA,eax
		invoke GetStockObject,DEFAULT_GUI_FONT
;		invoke SendMessage,hWnd,WM_GETFONT,0,0
		invoke SendMessage,ebx,WM_SETFONT,eax,TRUE
		invoke SendMessage,ebx,EM_SETSEL,0,80

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.elseif eax==WM_COMMAND

		mov ecx,wParam
		shr ecx,16
;-----------------------------------------------------------------------------

		.if ecx==CBN_SELCHANGE
			invoke SendMessage,hw_combo,CB_GETCURSEL,0,0
			invoke SendMessage,hw_combo,CB_GETITEMDATA,eax,0
			mov hP,eax

;-----------------------------------------------------------------------------

		.elseif ecx==CBN_DROPDOWN
			invoke FillCombo

;-----------------------------------------------------------------------------

		.elseif wParam==2000
			invoke IsDlgButtonChecked,hWnd,2000
			mov lck,eax

;-----------------------------------------------------------------------------

		.elseif wParam==2003 || wParam==2020							; SetParent / <SetOwner> = SetWindowLong(GWL_HWNDPARENT)

			.if lp>=63 || lck==0
				jmp @beep
			.endif

			invoke GetWindowLong,hW,GWL_EXSTYLE
			mov exstyle,eax
			invoke GetWindowLong,hW,GWL_STYLE
			mov style,eax
			invoke GetWindowLong,hW,GWL_ID
			mov id,eax
			invoke GetWindowRect,hW,addr rt
			invoke GetAncestor,hW,GA_PARENT
			mov esi,eax
			invoke MapWindowPoints,0,esi,addr rt,2

			xor edi,edi
			.if wParam==2003
				invoke SetParent,hW,hP
				test eax,eax
				jnz @f
			.else
				inc edi
				invoke SetLastError,0
				invoke SetWindowLong,hW,GWL_HWNDPARENT,hP			; at your own risk :-)
				test eax,eax
				jnz @f
				invoke GetLastError
				test eax,eax
				jz @f
			.endif
			invoke MessageBeep,MB_ICONHAND
			jmp @@@@
@@:
			mov ebx,lp
			mov ecx,ebx
			shl ebx,1
			add ebx,ecx
			shl ebx,4																	; lp*4*4*3  
			mov edx,offset undo_stack

			add ebx,edx
			mov edx,hW
			mov dword ptr [ebx],edx
			mov dword ptr [ebx +4],esi
			mov dword ptr [ebx +9*4],eax

			mov eax,rt.left
			mov dword ptr [ebx +2*4],eax
			mov eax,rt.top
			mov dword ptr [ebx +3*4],eax
			mov eax,rt.right
			mov dword ptr [ebx +4*4],eax
			mov eax,rt.bottom
			mov dword ptr [ebx +5*4],eax

			mov eax,exstyle
			mov dword ptr [ebx +6*4],eax
			mov eax,style
			mov dword ptr [ebx +7*4],eax

			mov dword ptr [ebx +8*4],edi

			mov eax,id
			mov dword ptr [ebx +10*4],eax

			inc lp
			mov eax,lp
			.if lp2<eax
				mov lp2,eax
			.endif

			invoke GetAncestor,hW,GA_PARENT
			mov esi,eax
			mov eax,point.x
			mov pt.x,eax
			mov eax,point.y
			mov pt.y,eax
			invoke MapWindowPoints,0,esi,addr pt,1
			invoke SetWindowPos,hW,0,pt.x,pt.y,0,0,SWP_NOSIZE OR SWP_FRAMECHANGED OR SWP_NOZORDER

;			invoke InvalidateRect,hW,0,1
;			invoke RedrawWindow,hW,0,0,RDW_ERASE OR RDW_INVALIDATE OR RDW_ALLCHILDREN

			invoke IsWindowVisible,hW
			.if eax!=0
				invoke ShowWindow,hW,SW_HIDE
				invoke ShowWindow,hW,SW_SHOWNORMAL
			.endif

@@@@:
			invoke SetDlgItemInt,hdlg,2006,lp,0

;-----------------------------------------------------------------------------

		.elseif wParam==2004
			.if lp>0
				invoke UndoRedo,1 												; Undo
			.else
				jmp @beep
			.endif

;-----------------------------------------------------------------------------

		.elseif wParam==2005
			mov eax,lp2
			.if eax>lp && eax<64
				invoke UndoRedo,0 												; Redo
			.else
@beep:
				invoke MessageBeep,MB_ICONHAND
			.endif

;-----------------------------------------------------------------------------

		.elseif wParam==2006
			invoke FullUndo															; Full Undo

;-----------------------------------------------------------------------------

		.elseif wParam==2013
			invoke CreateDialogParam,hinst,offset DlgName3,hX,0,0
			invoke OwnerInfo,eax

;-----------------------------------------------------------------------------

		.elseif wParam==2021
			invoke CreateDialogParam,hinst,addr DlgName2,hX,offset DlgProc2,1

;-----------------------------------------------------------------------------

		.elseif wParam==2022
			invoke DialogBoxParam,hinst,addr DlgName2,hX,offset DlgProc2,0

;-----------------------------------------------------------------------------

		.elseif wParam==2050
			invoke MessageBox,hX,offset _mb,offset _mb,0

;-----------------------------------------------------------------------------

		.elseif wParam==2017
			invoke SendMessage,hw_combo,WM_GETTEXT,255,addr buf
			invoke SendMessageTimeout,hX,WM_SETTEXT,0,addr buf,SMTO_ABORTIFHUNG,100,0

;-----------------------------------------------------------------------------

		.elseif wParam==2060
			invoke GetDlgItemInt,hWnd,2016,addr cid,0	; combobox
			.if cid!=0
				invoke SetWindowLong,hX,GWL_ID,eax
				invoke SetWindowPos,hX,0,0,0,0,0,SWP_NOZORDER OR SWP_NOMOVE OR SWP_NOSIZE OR SWP_FRAMECHANGED
				invoke InvalidateRect,hX,0,1
			.else
				jmp @beep
			.endif

;-----------------------------------------------------------------------------

		.elseif wParam==2018
			invoke PostMessage,hX,WM_CLOSE,0,0
;			invoke PostMessage,hX,WM_DESTROY,0,0

;-----------------------------------------------------------------------------

		.elseif wParam==2015													;  sWaP			( Window <--> Parent|Owner )
			.if lck==0
				jmp @beep
			.endif
			mov eax,hP
			mov ecx,hW
			mov hW,eax
			mov hP,ecx

;-----------------------------------------------------------------------------

		.elseif wParam==2008
			mov eax,HWND_TOPMOST
			mov ecx,SWP_NOSIZE OR SWP_NOMOVE OR SWP_FRAMECHANGED
			jmp @f
		.elseif wParam==2041
			mov eax,HWND_NOTOPMOST
			mov ecx,SWP_NOSIZE OR SWP_NOMOVE OR SWP_FRAMECHANGED
			jmp @f
		.elseif wParam==2042
			mov eax,HWND_TOP
			mov ecx,SWP_NOSIZE OR SWP_NOMOVE OR SWP_FRAMECHANGED
			jmp @f
		.elseif wParam==2043
			mov eax,HWND_BOTTOM
			mov ecx,SWP_NOSIZE OR SWP_NOMOVE OR SWP_FRAMECHANGED OR SWP_NOACTIVATE
@@:
			invoke SetWindowPos,hX,eax,0,0,0,0,ecx

;-----------------------------------------------------------------------------

		.elseif wParam==2009
			invoke IsWindowEnabled,hX
			xor eax,1
			invoke EnableWindow,hX,eax

;-----------------------------------------------------------------------------

		.elseif wParam==2010
			invoke IsIconic,hX
			.if eax!=0
				mov	eax,SW_RESTORE
			.else
				invoke IsZoomed,hX
				.if eax!=0
					mov	eax,SW_RESTORE
				.else
					mov eax,SW_MINIMIZE
				.endif
			.endif
			invoke ShowWindow,hX,eax

;-----------------------------------------------------------------------------

		.elseif wParam==2011
			invoke IsWindowVisible,hX
			.if eax==0
				mov eax,SW_SHOWNORMAL
			.else
				mov eax,SW_HIDE
			.endif
			invoke ShowWindow,hX,eax

;-----------------------------------------------------------------------------

		.elseif wParam==2014
			mov ebx,WS_POPUP
			jmp @f
		.elseif wParam==2012
			mov ebx,WS_CLIPCHILDREN
			jmp @f
		.elseif wParam==2025
			mov ebx,WS_CHILD
			invoke GetWindowLong,hX,GWL_ID
			mov edi,eax
@@:
			invoke StyleTrigger,hX,ebx
			.if ebx==WS_CHILD
				invoke GetWindowLong,hX,GWL_ID
				.if eax!=edi
;					and edi,0ffffh
					invoke SetDlgItemInt,hWnd,2016,edi,0
					invoke GetDlgItem,hWnd,2060
					invoke EnableWindow,eax,1
				.endif
			.endif

;-----------------------------------------------------------------------------

		.elseif wParam==2007					                ; all top-level windows (+ message-only)
			mov eax,0
			jmp @f
		.elseif wParam==2019													; all windows (+ message-only)
			mov eax,1
			jmp @f
		.elseif wParam==2035													; all descendants
			mov eax,4
			jmp @f
		.elseif wParam==2023													; all PID(hP)-windows (+ message-only)
			mov eax,2
			jmp @f
		.elseif wParam==2024													; all TID(hP)-windows (+ message-only)
			mov eax,3
			jmp @f
		.elseif wParam==2046													; all following windows: cursor over WindowRect + PtInRgn
			mov eax,5
;			jmp @f
;		.elseif wParam==2047													; all top-level windows (+ message-only) via GetWindow
;			mov eax,6
@@:
			mov filter,eax
			invoke CombolCaption
			mov edi,SWP_NOZORDER OR SWP_NOMOVE OR SWP_FRAMECHANGED
@@:
			invoke SendMessage,hw_combol,LB_RESETCONTENT,0,0
			invoke FillCombo
@@b:
			invoke SendMessage,hw_combol,LB_GETITEMHEIGHT,0,0
			mov ebx,eax
			add ebx,ebx
			invoke GetWindowRect,hw_combol,addr rt
			add rt.bottom,ebx
			mov eax,rt.right
			sub eax,rt.left
			mov ecx,rt.bottom
			sub ecx,rt.top
			invoke SetWindowPos,hw_combol,0,0,0,eax,ecx,edi

		.elseif wParam==2030
			invoke IsWindowVisible,hw_combol
			mov ebx,eax
			invoke GetWindowLong,hw_combol,GWL_STYLE
			.if ebx!=0
				and eax,not (WS_CAPTION OR WS_THICKFRAME OR WS_POPUP)
				or eax,WS_BORDER
				mov edi,SWP_NOZORDER OR SWP_NOMOVE OR SWP_FRAMECHANGED OR SWP_HIDEWINDOW
				invoke SetWindowLong,hw_combol,GWL_STYLE,eax
				jmp @@b
			.else
				or eax,WS_CAPTION OR WS_THICKFRAME OR WS_POPUP OR WS_BORDER
;				and eax,not WS_CHILD ; // БЕЗ этого "and", подражая MS (имеет же XP Explorer окошко класса DDEMLEvent с WS_POPUP|WS_CHILD, и ничего :-) )
				mov edi,SWP_NOZORDER OR SWP_NOMOVE OR SWP_FRAMECHANGED OR SWP_SHOWWINDOW
				invoke SetWindowLong,hw_combol,GWL_STYLE,eax
				jmp @b
			.endif

;-----------------------------------------------------------------------------

		.elseif wParam==2051
		  mov ebx,WS_EX_TOOLWINDOW
		  jmp @f
		.elseif wParam==2052
		  mov ebx,WS_EX_APPWINDOW
@@:
      invoke IsWindowVisible,hP
      push eax
      invoke ShowWindow,hP,SW_HIDE
      invoke GetWindowLong,hP,GWL_EXSTYLE
      xor eax,ebx
      invoke SetWindowLong,hP,GWL_EXSTYLE,eax
      invoke SetWindowPos,hP,0,0,0,0,0,SWP_NOZORDER or SWP_NOMOVE or SWP_NOSIZE or SWP_FRAMECHANGED
      pop eax
      .if eax!=0
        invoke ShowWindow,hP,SW_SHOW
      .endif

;-----------------------------------------------------------------------------

		.elseif wParam==2044
			mov ebx,hP
			cmp ebx,hMessage  ; (XP-pro-sp2)
			jz @messerr
@@: 	
			invoke GetWindow,ebx,GW_HWNDPREV        ; z-up
			mov ebx,eax
			invoke GetAncestor,ebx,GA_ROOTOWNER
			cmp eax,hP
			jz @b
			invoke GetWindow,ebx,GW_HWNDPREV
			jmp @f
		.elseif wParam==2045
			invoke GetWindow,hP,GW_HWNDNEXT         ; z-down
@@:
			invoke SetWindowPos,hP,eax,0,0,0,0,SWP_NOSIZE OR SWP_NOMOVE OR SWP_FRAMECHANGED OR SWP_NOACTIVATE

;-----------------------------------------------------------------------------

		.elseif wParam==2049
			invoke GetAncestor,hP,GA_PARENT
			jmp @ga_p
		.elseif wParam==2031					; Z-order for siblings
			mov eax,GW_HWNDFIRST
			jmp @f
		.elseif wParam==2032
			mov eax,GW_HWNDPREV
			jmp @f
		.elseif wParam==2033
			mov eax,GW_HWNDNEXT
			jmp @f
		.elseif wParam==2034
			mov eax,GW_HWNDLAST
			jmp @f
		.elseif wParam==2048
			mov eax,GW_CHILD
@@:
			mov ecx,hMessage  ; (XP-pro-sp2)
			.if ecx==hP && eax!=GW_CHILD
@messerr:
;				invoke MessageBox,hWnd,offset _HWND_MSG+4,0,40000h
			.else
				invoke GetWindow,hP,eax
@ga_p:
				.if eax!=0
					mov hP,eax
					invoke SendMessage,hw_combo,CB_GETCOUNT,0,0
					mov ebx,eax
					.while ebx!=0
						dec ebx
						invoke SendMessage,hw_combo,CB_GETITEMDATA,ebx,0
						.if eax==hP
							invoke SendMessage,hw_combo,CB_SETCURSEL,ebx,0
							.break
						.endif
					.endw
				.endif
			.endif

		.endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.elseif eax==WM_CTLCOLORLISTBOX

		.if mon!=0
			push eax
			invoke SetTextColor,wParam,00dd0000h
			pop eax
		.else
			mov eax,FALSE
		.endif
		jmp @ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.elseif eax==WM_CTLCOLORSTATIC

		mov edx,lParam
		.if edx==hw_2001
      invoke SetBkMode,wParam,TRANSPARENT
			invoke SetTextColor,wParam,0
			invoke GetStockObject,WHITE_BRUSH
		.else
			mov eax,FALSE
		.endif
		jmp @ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.elseif eax==WM_LBUTTONDOWN

		invoke DefWindowProc,hWnd,WM_NCLBUTTONDOWN,HTCAPTION,lParam

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.elseif eax==WM_NCRBUTTONDOWN && wParam==HTCAPTION

		invoke DefWindowProc,hWnd,0313h,0,lParam		; 0x0313 = undocumented (?)
;		invoke PostMessage,hWnd,0313h,0,lParam
;		invoke DefDlgProc,hWnd,0313h,0,lParam

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.elseif eax==WM_CONTEXTMENU

		invoke GetCursorPos,addr pt
		invoke MapWindowPoints,0,hWnd,addr pt,1
		invoke ChildWindowFromPoint,hWnd,pt.x,pt.y
		.if eax!=hWnd
			mov ebx,eax
			invoke IsWindowEnabled,ebx
			xor eax,1
			invoke EnableWindow,ebx,eax
		.else
			mov eax,FALSE
			jmp @ret
		.endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.elseif eax==WM_GETMINMAXINFO

		mov eax,lParam
		mov ecx,MinDlgWidth
		mov dword ptr [eax+6*4],ecx
		mov ecx,DlgHeight
		mov dword ptr [eax+7*4],ecx
		mov dword ptr [eax+9*4],ecx

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;	.elseif eax==WM_NOTIFY && wParam==2040		; lParam = pointer to  NMUPDOWN < NMHDR < hwndfrom, idfrom, notifcode >, ipos, idelta >
;
;		mov eax,hP
;		.if eax!=0 && eax!=hDesktop && eax!=hMessage && eax!=HWND_MESSAGE
;			mov eax,lParam
;			mov ecx,dword ptr [eax+2*4]
;			.if ecx==UDN_DELTAPOS
;				mov ecx,dword ptr [eax+4*4]
;				.if ecx<80000000h
;					invoke GetWindow,hP,GW_HWNDNEXT         ; z-down
;				.else
;					mov ebx,hP
;@@: 	
;					invoke GetWindow,ebx,GW_HWNDPREV        ; z-up
;					mov ebx,eax
;					invoke GetAncestor,ebx,GA_ROOTOWNER
;					cmp eax,hP
;					jz @b
;					invoke GetWindow,ebx,GW_HWNDPREV
;				.endif
;				invoke SetWindowPos,hP,eax,0,0,0,0,SWP_NOSIZE OR SWP_NOMOVE OR SWP_FRAMECHANGED OR SWP_NOACTIVATE
;			.endif
;		.endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.else
		mov eax,FALSE
		jmp @ret
	.endif
	mov eax,TRUE
@ret:
	ret
DlgProc endp

;#######################################################################################################

start:
	invoke GetModuleHandle,0
	mov hinst,eax
	invoke DialogBoxParam,eax,offset DlgName,0,offset DlgProc,0
	invoke ExitProcess,eax
	invoke InitCommonControls
end start

;#######################################################################################################
