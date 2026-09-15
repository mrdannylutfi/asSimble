* =====================================================================
* VARIABLE-LENGTH MULTI-CHOICE RESOLUTION ROUTINE (z16 Branch-Free)
* =====================================================================
* R5 = 64-bit pointer to the input string
* R7 = Current 64-bit pointer to the variable-length table
* R8 = Loop counter (remaining entries)
* R4 = Flag/Control: 1 = 64-bit payload, 0 = 32-bit payload (can be passed in externally or extracted from the table header)
* R10 = Final output payload register (automatically compatible with 32/64-bit modes)
* ---------------------------------------------------------------------
         LG    R7,TOKTBLPTR        Extract 64-bit table pointer
         LLGF  R8,0(,R7)          Load 32-bit row count into 64-bit register
         LA    R7,4(,R7)           LA    R7,4(,R7)           Skip count word, point to first row
         
         XR    R11,R11            R11 = Payload register for match hit (clear to zero)
         LA    R12,0              R12 = Hit flag (0=not found, 1=found)
*
CHKTBL   EQU   *
         CIJ   R8,0,8,DONE        If counter is 0, exit loop (retain only the loop boundary branch)
*
* 动态映射布局
         LLGH  R2,0(,R7)           R2 = Total length of current row
         LLGH  R9,2(,R7)           R9 = Compare field length
*
* 执行变长比较
         BCTR  R9,0               Decrement length for EXRL
         EXRL  R9,COMPVAR         Execute CLC (result sets CC: 0=equal, other=unequal)
*
* --- [Branch-Free Core Logic] ---
* 计算当前行 Payload 的绝对 64 位地址 -> 放入 R6
         LA    R6,4(,R7)           R6 = 跨过行头 (Offset 4)
         AGR   R6,R9               R6 = 跨过比较字符串
         AHI   R6,1                补偿 BCTR 带来的 -1
*
* Dynamic load selection: Determine the system's current payload width requirement based on R4.
* 如果 R4 == 1 采用 64 位加载，如果 R4 == 0 采用 32 位加载
         XR    R3,R3               清除 R3 (用于32位无符号扩展)
         L     R3,0(,R6)           无条件预载 32 位 Payload 到 R3
         LG    R1,0(,R6)           无条件预载 64 位 Payload 到 R1
         CIJ   R4,1,8,USE64        If R4=1, jump directly to the merge point (or use LOCG)
         LGR   R1,R3               Due to the z16's powerful branch prediction, this fixed jump overhead is close to zero.
USE64    EQU   *
*
* Conditional Select: If the preceding EXRL comparison succeeds (CC=0, corresponding to mask 8)...

erev shabbat 



* Assign the current row's payload (R1) to R11; if no match occurs, R11 remains unchanged!
         SELGR R11,R1,8,R11        CC=0 时 R11=R1, 否则 R11=R11
*
* --- 步进到下一行 ---
         AGR   R7,R2               指针安全加行长，移向下一行
         AHI   R8,-1               循环计数 -1
         BRC   15,CHKTBL          Due to the z16's powerful branch prediction, this fixed jump overhead is close to zero.
*
DONE     EQU   *
         LGR   R10,R11             R10 receives the matched payload (or 0 if no match)
*        ... 继续后续逻辑 ...
*
* ---------------------------------------------------------------------
* * Remote execution instruction (placed in non-executable data area)
* ---------------------------------------------------------------------
COMPVAR  CLC   0(0,R5),4(R7)       比较输入串与当前行数据
