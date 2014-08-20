{{
 ┌───────────────────────────────────────────────────────────────────┐
 │             MODBUS RTU SLAVE - DEF CON 22 Edition                 │
 │                                                                   │
 │                                                                   │
 └───────────────────────────────────────────────────────────────────┘

  
<Revision>

- 0.1

<Author>

- Mike B  

Acknowledgements
- Modbus RTU spin code is thanks to Paul Clyne (pacman on the Forums)  
- Based on code originally supplied by Olivier Jauzelon
- Kurenko - for his help with word/long/byte confusion
- Jon "JonnyMac" McPhalen and Ryan "1o57" Clarke for the DC22 badge design and source




A modbus request to read registers is of the form:-

   [01][03][00][04][00][64][05][E0]

   in above example, We want to read 100 holding registers, starting at 40005 from station 1

   [AA][BB][CC][DD][EE][FF][GG][HH]
   Where:-
        AA = station number being asked for data
        BB = Message type
                03 = Read multiple Holding registers    = 40000 series
                04 = Read Multiple Input registers      = 30000 series                                                               
                16 = Write Multiple Holding registers   = 40000 series
        CC + DD = Start Address of data from {be careful of the offset}
        EE + FF = Number of registers to get
        GG + HH = Checksum


}}
CON
_clkmode = xtal1 + pll16x
_xinfreq = 5_000_000

  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq               ' system freq as a constant
  MS_001   = CLK_FREQ / 1_000                                   ' ticks in 1ms
  US_001   = CLK_FREQ / 1_000_000                               ' ticks in 1us


  ' speed settings for power control/reduction
  ' -- use with clkset() instruction

  XT1_P16  = %0_1_1_01_111                                      ' 16x crystal (5MHz) = 80MHz
  XT1_PL8  = %0_1_1_01_110 
  XT1_PL4  = %0_1_1_01_101                                      
  XT1_PL2  = %0_1_1_01_100
  XT1_PL1  = %0_1_1_01_011
  RC_SLOW  = %0_0_0_00_001                                      ' 20kHz

'configure the parameters for the serial interface - the live one, not the debug one                
  RXpin = 31
  TXpin = 30
  Baud = 115_200
  MBAddress = 1  'modbus slave ID
   
  PAD3   = 27   ' touch pads
  PAD2   = 26
  PAD1   = 25
  PAD0   = 24

  IS_OFF    =  0                                                ' all bits off   
  IS_ON     = -1                                                ' all bits on    

  IS_LOW    =  0                                                
  IS_HIGH   = -1                                                

  IS_INPUT  =  0
  IS_OUTPUT = -1

 
OBJ

  ser  : "FullDuplexSerial"  
  pin  : "Input Output Pins"
                       
VAR

byte CogNo                      'Variable declaration

word R40000[3]                  ' 40000 series registers - Holding registers (read/write) - NORMALLY this would be defined in the TOP level object
word R30000[6]                  ' 30000 series registers - Input registers (read only) - NORMALLY this would be defined in the TOP level object

byte buffer[75]                 ' Modbus frame buffer - change if want to get more than 32 registers in single frame
byte RawBuffer[75]              ' the raw data in the serial port
byte InBuffer[25]               ' the request from the master
Byte OutBuffer[75]              ' the data we will transmit back to the master 
long  ms001                     ' set ticks per millisecond for waitcnt
long  us001                     ' set ticks per microsecond for waitcnt
byte padbuffer[4]

                             
PUB Main | idx, ExeceptionCode, FrameEndCountOffset, FrameEndFlag, RChar, FrameEndTgt, i, FrameCheck

   'This is run in a new cog
   'it's function is to check the DataIn stream and bung that data into InBuffer[0] to InBuffer[...]
   'When it gets a full buffer or we have recieved a frame end space (3.5 times character length) then set the EndFrameFlag

   ' a single bit is 1/BaudRate of time long,
   '  thus an 11 bit long character is 11 * 1/Baud time long (so for 9600 we get something like 1.14583333 mS)
   '  A frame in RTU is terminated by a 3.5 character long space.
   
   'pre-load some data into the Input registers (remember they are read only by the host}
   '  That way if you poll those registers you get meaningful data
   R30000[0] := "D"
   R30000[1] := "E"
   R30000[2] := "F"
   R30000[3] := "C"
   R30000[4] := "O"
   R30000[5] := "N"
   R40000[0] := 0
   R40000[1] := 0
   R40000[2] := 0

  'set LED outputs for DEF CON 22 modbadge    
   pin.Outs(16, 23, %00000000)

   ms001 := clkfreq / 1_000    ' set ticks per millisecond for waitcnt
   us001 := clkfreq / 1_000_000 

   'start the modbus serial on USB
   Ser.start(RXPin,TXPin,0,Baud)
 
   FrameEndCountOffset := (CLKFREQ / baud * 11 * 35 / 10) ' you can't multiply by a decimal so use integer and then divide by 10  
                                                          ' * 35 / 10 == *3.5
   FrameCheck := False

   idx := 1                     'we start at one as we will use [0] to store the idx count

   repeat
        

      RChar := ser.rxcheck  
      
      pin.Toggle(23)
        UpdateInRegs
        UpdateOutRegs

      if RChar <> -1                                    'A new char has arrived
                                                        
        RawBuffer[idx++] := RChar                       'so put it in the buffer @ position idx and increment idx
        FrameEndTgt := cnt + FrameEndCountOffset        'and set the 'future' count vale so if we dont get a char between now and then
                                                        ' we know that we have got a frame time timing
        FrameCheck := True
                                                                
      'there isn't a character
      'so we might be at the end of the frame'
      'check to see if we are....
      
      if ((cnt >= FrameEndTgt) AND FrameCheck )OR (idx > 73)

        bytefill (@Inbuffer, 0, 25)
        bytemove (@InBuffer,@RawBuffer,24)              'Copy Incomming Raw Buffer to InBuffer
        InBuffer[0] := idx

        bytefill (@RawBuffer, 0, 75)                    'Clear Raw Buffer
        idx := 1
        FrameCheck := False

        CheckMessage(@InBuffer)
      

       


Pub UpdateOutRegs

      'turn on LEDs on DEF CON 22 badge coresponding to registers
      if R40000[0] > 0
        pin.High(16)
      else
        pin.Low(16)

      if R40000[1] > 0
        pin.High(17)
      else
        pin.Low(17)

      if R40000[2] > 0
        pin.High(18)
      else
        pin.Low(18)



Pub UpdateInRegs
      padbuffer := read_pads ' read the touchpads on DEF CON 22 badge

      case padbuffer
        %0001:
          R30000[0]++
          pin.toggle(22)       
          pause(250)  
      
        %0010:
          R30000[1]++
          pin.toggle(21)       
          pause(250)  
      
        %0100:
          R30000[2]++
          pin.toggle(20)       
          pause(250)  
      
        %1000:
          R30000[3]++
          pin.toggle(19)       
          pause(250)  


        

Pub read_pads

'' Reads and returns state of touch pad inputs
'' -- swaps LSB/MSB for correct binary input

  outa[PAD3..PAD0] := IS_HIGH                                   ' charge pads (all output high)   
  dira[PAD3..PAD0] := IS_OUTPUT
    
  dira[PAD3..PAD0] := IS_INPUT                                  ' float pads   
  pause(50)                                                     ' -- allow touch to discharge

  return (!ina[PAD3..PAD0] & $0F) >< 4                          ' return "1" for touched pads)

Pub pause(ms) | t

'' Delay program in milliseconds
'' -- ensure set_speed() used before calling

  t := cnt                                                      ' sync to system counter
  repeat (ms #>= 0)                                             ' delay > 0
    waitcnt(t += ms001)                                         ' hold 1ms

        
Pri CheckMessage (mesg)   | CRCVal, CRCpos1, CRCpos2

  'NOTE the first element of the array contains the length of the array
    
  if (byte[mesg][0] < 8)
    'Frame Too Short

  elseif (byte[mesg][0] > 70)
    'Frame too long
    
  elseif (byte[mesg][1] <> MBAddress)
    'not for this station so ignore it
       
  else

    ' we have a correctly addressed, sized, message

    ' Lets check its CRC

     CRCVal := CheckCRC(mesg)
     CRCpos1 := byte[mesg][0] - 1
     CRCpos2 := byte[mesg][0] - 2
     
     
    If byte[@CRCval][0] <> byte[mesg][CRCpos2] OR byte[@CRCval][1] <> byte[mesg][CRCpos1]

       'CRC mismatch

    else

       ' might be OK, check command type
   
      Case byte[mesg][2]

        $03, $04:
          '03h = Read Holding Register(s) - Read/Write registers -(40000 Series)
          '04h = Read Input Register(s) - Read only registers -(30000 Series)   

          if ((byte[mesg][5] > 0) or (byte[mesg][6] > 6))
            'Only 6 registers supported

          elseif (byte[mesg][3] <> 0) OR (byte[mesg][4] > 5) OR (byte[mesg][4] + byte[mesg][6] > 6)
            'Only 6 registers supported 
           
          else
            ReadRegisters(mesg)
        
        $06 :
          '06h = Write Single Holding register (40000 Series)
          
          if ((byte[mesg][4] > 3))
            'Only 3 registers supported 

          else
            ProcessCode06(mesg)

           
        other :

PRI ReadRegisters (buf) | i, BaseReg, ResponseBuf[6], CRCval, CRCpos1, CRCpos2

   'Read Multiple registers
   ' input registers are the 30000 series and are accessed by a type 04 command
   ' holding registers are the 40000 series and are accessed by a type 03 command

    ResponseBuf.byte[1] := byte[buf][1]       'the first byte of any response is the station number
    
    ResponseBuf.byte[2] := byte[buf][2]       'the next byte of any response is the function code used to call the data

    ResponseBuf.byte[3] := byte[buf][6] * 2   'the next byte is the number of bytes of data we are retuning, NB: 2 bytes per register   
    
    BaseReg := byte[buf][4]         ' the first register we need to return data from
    
    repeat i from 4 to ResponseBuf.byte[3] + 3
    
      Case byte[buf][2]
        3:
    
          '03 = Read holding registers - Holding registers are the 40000 series
          ResponseBuf.byte[i++] := R40000{0}.byte[2*BaseReg+1]  'High byte of R40000[x]
          ResponseBuf.byte[i] := R40000{0}.byte[2*BaseReg]   'Low byte of R40000[x]
          
          
        4:
          '04 = Read INPUT registers - Input registers are the 30000 series
          ResponseBuf.byte[i++] := R30000{0}.byte[2*BaseReg+1]  'High byte of R30000[x]
          ResponseBuf.byte[i] := R30000{0}.byte[2*BaseReg]   'Low byte of R30000[x]
                   
      BaseReg++

      
    ResponseBuf.byte[0] := byte[buf][6] * 2 + 6                        '+ 2 for CRC space

    CRCval := CheckCRC(@responseBuf)

    CRCpos1 := ResponseBuf.byte[0] - 1
    CRCpos2 := ResponseBuf.byte[0] - 2     
     
    ResponseBuf.byte[CRCpos2] := byte[@CRCval][0]
    ResponseBuf.byte[CRCpos1] := byte[@CRCval][1]
    
    SendOut(@ResponseBuf)

PRI ProcessCode06 (buf)| i, ResponseBuf[9], CRCval, Reg

  'code 06 Hex = Write Single Holding register (40000 Series)

  Reg := byte[buf][4]         ' the register we are writing to

  R40000[reg] := byte[buf][5] * 256 + byte[buf][6]

  ' now generate and send the normal response (which is an echo of the request)


  ResponseBuf.byte[1] := byte[buf][1]       'the first byte of any response is the station number
    
  ResponseBuf.byte[2] := byte[buf][2]       'the next byte of any response is the function code used to call the data
  
  ResponseBuf.byte[3] := byte[buf][3]       'the next byte is the high byte of the starting address
  
  ResponseBuf.byte[4] := byte[buf][4]       'then the low byte of the starting address
     
  ResponseBuf.byte[5] := byte[buf][5]       'Data high byte
  
  ResponseBuf.byte[6] := byte[buf][6]       'Data low byte


  ResponseBuf.byte[0] := 9                  '+ 2 for CRC space
 
  CRCval := CheckCRC(@responseBuf)
   
  ResponseBuf.byte[7] := byte[@CRCval][0]
  ResponseBuf.byte[8] := byte[@CRCval][1]

  SendOut(@ResponseBuf)


PRI SendOut (buf)| j

  ' Transmits the data back to the host system.

  '  params:  buf - the data stream we want to transmit             
  '  return:  none
  
  'NOTE the first element of the array contains the length of the array       
  ' thus we need to send out buf[0] bytes of data
    
  repeat j from 1 to (byte[buf][0] -1 ) 
      
    'pst.TX(byte[buf][j])
    Ser.TX(byte[buf][j]) 

PRI CheckCRC(buf) | i, CRCVal

  'Generate our own CRC values and return it

  '  params:  buf - the data stream we want to generate the CRC for             
  '  return:  CRCVal - the result of the CRC calculation [2 bytes 'wide']


   'remember that the first byte of Packet contains the length of the messgage
   'and the last two elements of InBuffer are the CRC

    

   CRCVal := $FFFF

   if byte[buf][0] > 2         ' no point in even doing this if we are only two byes long 
    
     i:= 1
     repeat while i < ((byte[buf][0])-2)

        CRCVal ^= byte[buf][i++] 'XOR and store back in CRCVal 
                                          
      repeat 8
         CRCVal := CRCVal >> 1 ^ ($A001 & (CRCVal & 1 <> 0))  'XOR and store back in result

   result := CRCVal

dat

{{

  Terms of Use: MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
  software and associated documentation files (the "Software"), to deal in the Software
  without restriction, including without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

}}   
