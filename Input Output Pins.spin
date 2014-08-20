{{Input Output Pins.spin

This object has convenience methods for
configuring, monitoring and controlling
the Propeller microcontroller's input/
output pins (I/O pins), either individually
or in groups.

See end of file for author, version,
copyright and terms of use.

Examples in each method's documentation
assumes that this object was declared in a
program and nicknamed pin, like this:

  Example Program with pin Nickname
 ┌────────────────────────────────────────┐
 │ ''Sets P9 to output-high (3.3 V).      │
 │ OJB                                    │
 │   pin : "Input Output Pins"            │
 │                                        │
 │ PUB Go                                 │
 │   pin.High(9)  ' P9 output-high        │
 │   repeat       ' Endless loop keeps    │
 │                ' cog running.          │
 └────────────────────────────────────────┘

IMPORTANT  This object is a collection of
           "convenience methods".  For more
           I/O pin monitoring and control
           options, you can use the Spin
           Language's OUTA, OUTB, INA, INB,
           and DIRA, DIRB registers.  To
           find out more and see examples
           of how they can be used, look
           them up in the Propeller Manual.

BUGS       Please send bug reports,
&          questions, suggestions, 
UPDATES    and improved versions of this
           object to alindsay@parallax.com,
           and check back periodically for
           updated versions.                    
}}

PUB High(pin)
{{Set I/O pin to output-high = 3.3 V.

Parameter:

  pin = I/O pin number

Example:

  pin.High(9)  ' P9 output-high

  See Example with pin Nickname above.
}}
  
  outa[pin] := 1
  dira[pin] := 1

PUB Low(pin)
{{Set I/O pin to output-low = 0 V.

  PARAMETER: pin = I/O pin number

Example:

  pin.Low(9)   ' P9 output-low
}}
  
  outa[pin] := 0
  dira[pin] := 1  
  
PUB In(pin) : state
{{Sets I/O pin to input and checks state
of voltage applied to the pin.
 
  PARAMETER: pin = I/O pin number
  RETURNS: state = 1 if above 1.65 V
                   0 if below 1.65 V

Example:

             Returns 1 if voltage at
             pin is above 1.65 V,   
             or 0 if it's below.
             │   
        ┌────┴────┐
  var := pin.In(3)  
 └──┬───┘ 
    │
    Result copied to a  
    variable named var.
}}

  dira[pin] := 0                                                                                                            
  state := ina[pin]

PUB Out(pin, state)
{{Set I/O pin to an output state.
         
  PARAMETERS:
    pin   = I/O pin number
    state = 1 -> 3.3 V output.
            0 -> 0 V   output.

  RETURNS:
    state = I/O pin number

Examples:
                 Set P9 to 
       ┌──────── output-high (3.3 V) 
                 
  pin.Out(9, 1)
 
  pin.Out(9, 0)
                  
       └──────── Set P9 to 
                 output-high (3.3 V)
}}

  state := outa[pin] := state
  dira[pin] := 1
                
PUB Dir(pin, direction)
{{Set an I/O pin's direction to either
output or input.

  PARAMETERS:
    pin       = I/O pin number
    direction = 1 -> output.
                0 -> input.

Examples:
                 
       ┌──────── Set P9 to output.
                 
  pin.Dir(9, 1)
 
  pin.Dir(9, 0)
                  
       └──────── Set P9 to input.
}} 

  dira[pin] := direction

PUB GetDir(pin) : direction
{{Check an I/O pin's direction setting.

  PARAMETERS:
    pin       = I/O pin number

  RETURNS:
    direction = 1 -> output.
                0 -> input.

             Returns 1 if pin is an output
             or 0 if it's an input. 
             │   
        ┌────┴────────┐
  var := pin.GetDir(3)  
 └──┬───┘ 
    │
    Result copied to a  
    variable named var.
}}

  direction := dira[pin]

PUB Toggle(pin) : newstate
{{Change an I/O pin's output state to the
opposite of its current state (from high
to low or from low to high).

  PARAMETERS:
    pin = I/O pin number

Example:

      ┌────────── Toggle I/O pin to output  
      │           opposite of its current
                 state. 
  pin.Toggle(9)
}} 

  !outa[pin]
  dira[pin] := 1

PUB Reverse(pin) : newdir
{{Reverse I/O pin's direction (from
output to input or vice-versa).

  PARAMETERS:
    pin = I/O pin number

Example:

      ┌────────── Reverse the direction of  
                 I/O pin P9            
  pin.Reverse(9)
}} 

  !dira[pin]

PUB Highs(first, last)
{{Set a group of I/O pins to output-high.

  PARAMETERS:
    first = first pin in the pin group
    last  = last pin in the pin group

Example:


      ┌────────── Set I/O pins P8..P15 to   
                 output-high.
  pin.Highs(8, 15)
}} 

  outa[first..last] := true
  dira[first..last] := true

PUB Lows(first, last)
{{Set a group of I/O pins to output-high.

  PARAMETERS:
    first = first pin in the pin group
    last  = last pin in the pin group

Example:

      ┌────────── Set I/O pins P8..P15 to   
                 output-low.
  pin.Lows(8, 15)
}} 

  outa[first..last] := false
  dira[first..last] := true
  
PUB Ins(first, last) : states
{{Sets a group of I/O pins to input and
reports states of voltages applied to each
pin.
 
  PARAMETERS:
    first = first pin in the pin group
    last  = last pin in the pin group
  RETURNS:
    states = binary representation of the
             pin states with 1s for pins
             with more than 1.65 V applied
             and 0s for pins with less.

    How binary values in the states return
    value states correspond to I/O pin
    states:────┐
        ┌──────┴────┬────────────┐
                               
    %first-pin, second-pin,...last-pin                   


Example:     Returns result with binary 1s
             for pins with voltage above
             1.65 V and 0s for below.  With
             first set to 7 and last set to
             3, the Binary value will be:
             (P7,P6,P5,P4,P3).
             │   
        ┌────┴────────┐
  var := pin.Ins(7..3)  
 └──┬───┘ 
    │
    Binary result copied to var.
    Lets say that 3.3 V is applied to
    P7, P6, P3 and 0 V is applied to
    P5 and P4.  Then var's binary
    value would be %11001.
                    
                 P7─┘││││
                 P6──┘│││
                 P5───┘││
                 P4────┘│ 
                 P3─────┘

    Note: pin.Ins(3..7) would return the
    values in reverse order because the
    values of the first and last parameters
    are swapped.  The new result would be:
      %01100
      P3...P7    
}}
                              
  dira[first..last] := false
  states := ina[first..last]
                                                                                                              
PUB Outs(first, last, states)
{{Sets a group of I/O pins to output and
sets each of their voltages.
 
  PARAMETERS:
    first  = first I/O pin in the group
    last   = last I/O pin in the group
    states = binary representation of the
             high/low pattern of output
             states with 1s corresponding
             to high signals and 0s to
             low signals.

    How binary values in states correspond
    to I/O pin states:────┐
        ┌───────────┬─────┴──────┐
                               
    %first-pin, second-pin,...last-pin                   

Example:

  pin.Outs(15, 12, %1101)
                    
    P15 high     ───┘│││   
    P14 high     ────┘││  
    P13 low      ─────┘│ 
    P12 high     ──────┘

    Note: pin.outs(12..15) would result in 
    a reverse order high/low pattern, with
    P12 and P13 high, P14 low and P15 high.
}}

  dira[first..last] := true
  outa[first..last] := states

PUB Dirs(first, last, directions)
{{Sets the directions of a group of I/O pins
starting with first and ending with last to
an output/input pattern defined by the binary
1s and 0s in directions.
 
  PARAMETERS:
    first  = first I/O pin in the group
    last   = last I/O pin in the group
    states = binary representation of the
             output/input pattern of I/O
             pin directions.

    How binary values in states correspond
    to I/O pin directions:────┐
        ┌───────────┬─────────┴──┐
                               
    %first-pin, second-pin,...last-pin                   

Example:

  pin.Dirs(15, 12, %1010)
                    
    P15 output   ───┘│││   
    P14 input    ────┘││  
    P13 output   ─────┘│ 
    P12 input    ──────┘

    Note: pin.Ins(12..15) would result in a
    reverse order high/low pattern, with
    P12 and P13 high, P14 low and P15 high.
}}

  dira[first..last] := directions

PUB GetDirs(first, last) : directions
{{Reports the directions of a group of I/O
pins from first to last.  The return value
contains a binary pattern of the pin
directions with 1s indicating output and
0s indicating input.
 
  PARAMETERS:
    first = first pin in the pin group
    last  = last pin in the pin group
  RETURNS:
    states = binary representation of the
             output/input pattern of I/O
             pin directions.

    How binary values in states correspond
    to I/O pin directions:────┐
        ┌───────────┬─────────┴──┐
                               
    %first-pin, second-pin,...last-pin                   


Example:     Returns result with binary 1s
             for I/O pins with 1s for I/O
             pins set to output and 0s for
             I/O pins set to input.  With
             first set to 7 and last set to
             3, the binary value report the
             directions of:
             (P7,P6,P5,P4,P3).
             │   
        ┌────┴────────┐
  var := pin.Dirs(7..3)  
 └──┬───┘ 
    │
    Binary result copied to var.
    Lets say that P7, P6, P3 are set to
    output and P5 and P4 are set to input.
    var's binary value would be %11001.
                                 
                              P7─┘││││
                              P6──┘│││
                              P5───┘││
                              P4────┘│ 
                              P3─────┘

    Note: pin.Dirs(3..7) would return the
    directions in reverse order because the
    values of the first and last parameters
    are swapped.  The new result would be:
      %01100
      P3...P7    
}}

  directions := dira[first..last]

PUB Toggles(first, last) : newstates
{{Toggles the output states of a group of
I/O pins.

  PARAMETERS:
    first = first pin in the pin group
    last  = last pin in the pin group

Example:

  pin.Toggles(12, 15)

 Before Toggles     After Toggles:

   P15 = high       P15 = low   
   P14 = input      P14 = input (no change*)    
   P13 = high       P13 = low   
   P12 = low        P12 = high

 P14's output register still toggles.  If it
 is made an output after Toggle, it will have
 the opposite output state from what it would
 have had before Toggle was called.      
}} 

  newstates := !outa[first..last]  

PUB Reverses(first, last) : newdirs
{{Set a group of I/O pins to output-high.

  PARAMETERS:
    first = first pin in the pin group
    last  = last pin in the pin group

Example:


      ┌────────── Set I/O pins P8..P15 to   
                 output-high.
  pin.Highs(8, 15)
}} 

  newdirs := !dira[first..last]

DAT                                           

{{
File:      Input Output Pins.spin
Date:      2012.01.30
Version:   0.31
Author:    Andy Lindsay
Copyright: (c) 2012 Parallax Inc.  

┌────────────────────────────────────────────┐
│TERMS OF USE: MIT License                   │
├────────────────────────────────────────────┤
│Permission is hereby granted, free of       │
│charge, to any person obtaining a copy      │
│of this software and associated             │
│documentation files (the "Software"),       │
│to deal in the Software without             │
│restriction, including without limitation   │
│the rights to use, copy, modify, merge,     │
│publish, distribute, sublicense, and/or     │
│sell copies of the Software, and to permit  │
│persons to whom the Software is furnished   │
│to do so, subject to the following          │
│conditions:                                 │
│                                            │
│The above copyright notice and this         │
│permission notice shall be included in all  │
│copies or substantial portions of the       │
│Software.                                   │
│                                            │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT   │
│WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES │
│OF MERCHANTABILITY, FITNESS FOR A           │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN  │
│NO EVENT SHALL THE AUTHORS OR COPYRIGHT     │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR │
│OTHER LIABILITY, WHETHER IN AN ACTION OF    │
│CONTRACT, TORT OR OTHERWISE, ARISING FROM,  │
│OUT OF OR IN CONNECTION WITH THE SOFTWARE   │
│OR THE USE OR OTHER DEALINGS IN THE         │
│SOFTWARE.                                   │
└────────────────────────────────────────────┘
}}
