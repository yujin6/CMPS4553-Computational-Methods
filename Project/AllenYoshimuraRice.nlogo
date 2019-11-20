; Created on Thu Nov. 15, 2019
;
; @author: Joshua Allen, Yujin Yoshimura
; CMPS 4553 Computational Method
; Dr. Tina Johnson
; Final Project
;
; This demonstration shows the historical simulation of spread of rice cultivation.
extensions  [ csv ]

; These are the parameters that affects feasibility of rice cultivation.
patches-own [
  altitude
  temperature
  precipitation
  river
  cultivated
]

; There are two kinds of turtles: person and rice.
; rices does not actually represent the plant rice itself, but represents persons with
; a knowledge of rice cultivation.
breed [ persons person ]
breed [ rices rice ]
turtles-own [
  hunger
]

; @function name: load-map
; Loads parameters from csv files and initialize all patches.
to load-map
  clear-all
  file-close-all
  set-patch-size 10
  load-altitude
  load-temperature
  load-precipitation
  load-river
  ask patches
  [ set cultivated 0 ]
  set-color
  reset-ticks
end

; @function name: initialize
; Set initial coordinate where rice cultivation begins.
to initialize
  clear-turtles
  clear-all-plots
  initialize-rice
  set-color
  reset-ticks
end

; @function name: go
; Simulates the spread of rice cultivation.
to go
  spawn
  move
  update-hunger
  cultivate
  show-persons
  set-color
  tick
end

; @function name: initialize-rice
; Sets initial coordinate where rice cultivation begins.
to initialize-rice
  ask patches [
    (ifelse
      pycor = (Latitude - 60) and pxcor = (Longitude - 23) [ set cultivated 1 ]
    ; else commands
    [ set cultivated 0 ]
    )
  ]
end

; @function name: show-persons
; Toggles between showing and hiding persons turtles.
to show-persons
  if Show-People = false [ ask persons [ set hidden? true  ] ]
  if Show-People = true  [ ask persons [ set hidden? false ] ]
end

; @function name: spawn
; Spawns persons and rices according to the conditions.
to spawn
  ask patches [
    if pxcor > 1 and pxcor < 126 and pycor < -1 and pycor > -62 [
      if altitude > 2 and altitude < 8 and precipitation > 3 [
        ; probability of spawning rice in cultivated area is cultivation level * 5%, given that persons are in the cultivated area.
        if random 20 < (cultivated * count persons-here) [
          sprout-rices 1 [
            set color 44
            set shape "plant"
            set hidden? true
            set hunger 0
          ]
        ]
        ; probability of spawning person in normal area is 0.02 %
        if random 5000 < 1 [
          sprout-persons 1 [
            set color black
            set shape "person"
            set hunger 0
          ]
        ]
      ]
      if river > 1 [
        ; probability of spawning person in area with river is 0.1 %
        if random 1000 < 1 [
          sprout-persons 1 [
            set color black
            set shape "person"
            set hunger 0
          ]
        ]
      ]
      if altitude = 8 or precipitation = 3 or precipitation = 2 [
        ; probability of spawning person in barren area is 0.01 %
        if random 10000 < 1 [
          sprout-persons 1 [
            set color black
            set shape "person"
            set hunger 0
          ]
        ]
      ]
      if altitude = 9 or precipitation = 1 [
        ; probability of spawning person in severe area is 0.005 %
        if random 20000 < 1 [
          sprout-persons 1 [
            set color black
            set shape "person"
            set hunger 0
          ]
        ]
      ]
    ]
  ]
end

; @function name: move
; Kills turtles out of bound, and move turtles.
to move
  ask turtles [
    if xcor < 1 or xcor > 126  [ die ]
    if ycor > -1 or ycor < -62 [ die ]
  ]
  move-persons
  move-rices
end

; @function name: move-persons
; Moves persons according to the terrain.
to move-persons
  ask persons [
    ; Kills persons starved.
    if hunger >= 100 [ die ]
    ; Kill persons in an overcrowded area, as the terrain cannot sustain the population.
    if count persons-here > (1 + [ cultivated ] of patch-here) [ die ]
    right random 360
    (ifelse
      [ river ] of patch-ahead 1 = 3    [ forward 1 ]
      [ altitude ] of patch-ahead 1 = 1 [ forward 0 ]
      [ altitude ] of patch-ahead 1 = 2 [ forward 0 ]
      [ altitude ] of patch-ahead 1 = 8 [ forward 0.1 ]
      [ altitude ] of patch-ahead 1 = 9 [ forward 0.01 ]
      ; else commands
      [ forward 0.5 ]
    )
    ; Hides persons crossing ocean.
    (ifelse
      [ altitude ] of patch-here < 3 [ set color blue ]
      ; else commands
      [ set color black ]
    )
  ]
end

; @function name: move-persons
; Moves rices according to the terrain.
to move-rices
  ask rices [
    ; Kills rices starved.
    if hunger >= 300 [ die ]
    ; Kills rices in an overcrowded area, as the terrain cannot sustain the population.
    if count rices-here > 10 [ die ]
    (ifelse
      [ river ] of patch-ahead 1 = 2 [ right (random 20 - 10) ]
      ; else commands
      [ right random 360 ]
    )
    (ifelse
      [ river ] of patch-ahead 1 = 1 [ forward 1 ]
      [ river ] of patch-ahead 1 = 2 [ forward 1 ]
      [ river ] of patch-ahead 1 = 3 [ forward 0.2 ]
      [ altitude ] of patch-ahead 1 = 9 [ forward 0.02 ]
      ; else commands
      [ forward 0.08 ]
    )
    ; Hides persons crossing ocean.
    (ifelse
      [ altitude ] of patch-here < 3 [ set color blue ]
      ; else commands
      [ set color 44 ]
    )
  ]
end

; @function name: update-hunger
; Updates hunger level of all turtles according to the terrain.
to update-hunger
  ask turtles [
    (ifelse
      [ cultivated ] of patch-here > 0    [ set hunger hunger ]
      [ river ] of patch-here = 3         [ set hunger hunger ]
      [ altitude ] of patch-here = 1      [ set hunger hunger + 50 ]
      [ altitude ] of patch-here = 2      [ set hunger hunger + 5 ]
      [ altitude ] of patch-here = 8      [ set hunger hunger + 10 ]
      [ altitude ] of patch-here = 9      [ set hunger hunger + 25 ]
      [ precipitation ] of patch-here = 1 [ set hunger hunger + 15 ]
      [ precipitation ] of patch-here = 2 [ set hunger hunger + 10 ]
      [ precipitation ] of patch-here = 3 [ set hunger hunger + 6 ]
      [ precipitation ] of patch-here = 4 [ set hunger hunger + 3 ]
    ; else commands
    [ set hunger hunger + 1 ]
    )
  ]
end

; @function name: cultivate
; Rices in uncultivated terrain cultivates.
to cultivate
  ask patches [
    ; If rices are not in the terrain, do not cultivate.
    ; If the temperature is too cold, do not cultivate. Temperature bound is set to 8.
    ; If the precipitation is too arid, do not cultivate. Precipitation and river bound is set to 3.
    ; If the cultivated level is too high, do not cultivate. Maximum cultivation level is set to 5.
    if count rices-here > cultivated and temperature > 8 and (precipitation + river) > 3 and cultivated < 5 [
      set cultivated cultivated + 1
    ]
  ]
end

; @function name: set-color
; Sets color according to the user's choice.
to set-color
  (ifelse
    color_by = "Satellite"     [ show-satellite ]
    color_by = "Altitude"      [ show-altitude ]
    color_by = "Temperature"   [ show-temperature ]
    color_by = "Precipitation" [ show-precipitation ]
    color_by = "River"         [ show-river ]
    ; else commands
    [ show-satellite ]
  )
end

; @function name: show-satellite
; Sets color according to the satellite image.
to show-satellite
  ask patches [
    (ifelse
      altitude = 1 [ set pcolor blue ]
      altitude = 2 [ set pcolor blue ]
      cultivated > 0 [ set pcolor 44 ]
      precipitation = 1 [ set pcolor 48 ]
      precipitation = 2 [ set pcolor 58 ]
      precipitation = 3 [ set pcolor 57 ]
      precipitation = 4 [ set pcolor 56 ]
    ; else commands
    [ set pcolor green ]
    )
  ]
  ask rices [
    set hidden? true
  ]
end

; @function name: show-altitude
; Sets color according to the altitude.
to show-altitude
  ask patches [
    (ifelse
      altitude = 1 [ set pcolor blue ]
      altitude = 2 [ set pcolor sky ]
      altitude = 3 [ set pcolor green ]
      altitude = 4 [ set pcolor lime ]
      altitude = 5 [ set pcolor 67 ]
      altitude = 6 [ set pcolor 47 ]
      altitude = 7 [ set pcolor 27 ]
      altitude = 8 [ set pcolor brown ]
      altitude = 9 [ set pcolor 33 ]
    ; else commands
    [ set pcolor white ]
    )
  ]
  ask rices [
    (ifelse
      [ altitude ] of patch-here < 3 [ set hidden? true ]
    ; else commands
    [ set hidden? false ]
    )
  ]
end

; @function name: show-satellite
; Sets color according to the temperature.
to show-temperature
  ask patches [
    (ifelse
      temperature = 1 [ set pcolor 104 ]
      temperature = 2 [ set pcolor blue ]
      temperature = 3 [ set pcolor sky ]
      temperature = 4 [ set pcolor cyan ]
      temperature = 5 [ set pcolor 77 ]
      temperature = 6 [ set pcolor turquoise ]
      temperature = 7 [ set pcolor green ]
      temperature = 8 [ set pcolor lime ]
      temperature = 9 [ set pcolor 67 ]
      temperature = 10 [ set pcolor 47 ]
      temperature = 11 [ set pcolor yellow ]
      temperature = 12 [ set pcolor 27 ]
      temperature = 13 [ set pcolor orange ]
      temperature = 14 [ set pcolor red ]
      temperature = 15 [ set pcolor 14 ]
    ; else commands
    [ set pcolor white ]
    )
  ]
  ask rices [
    (ifelse
      [ altitude ] of patch-here < 3 [ set hidden? true ]
    ; else commands
    [ set hidden? false ]
    )
  ]
end

; @function name: show-satellite
; Sets color according to the precipitation.
to show-precipitation
  ask patches [
    (ifelse
      precipitation = 1 [ set pcolor 46 ]
      precipitation = 2 [ set pcolor 48 ]
      precipitation = 3 [ set pcolor 68 ]
      precipitation = 4 [ set pcolor 58 ]
      precipitation = 5 [ set pcolor 78 ]
      precipitation = 6 [ set pcolor 88 ]
      precipitation = 7 [ set pcolor 98 ]
      precipitation = 8 [ set pcolor 96 ]
      precipitation = 9 [ set pcolor 106 ]
      precipitation = 10 [ set pcolor blue ]
      precipitation = 11 [ set pcolor 104 ]
      precipitation = 12 [ set pcolor 103 ]
    ; else commands
    [ set pcolor white ]
    )
  ]
  ask rices [
    (ifelse
      [ altitude ] of patch-here < 3 [ set hidden? true ]
    ; else commands
    [ set hidden? false ]
    )
  ]
end

; @function name: show-satellite
; Sets color according to the river.
to show-river
  ask patches [
    (ifelse
      river = 1 [ set pcolor blue ]
      river = 2 [ set pcolor blue ]
      river = 3 [ set pcolor cyan ]
    ; else commands
    [ set pcolor white ]
    )
  ]
  ask rices [
    (ifelse
      [ altitude ] of patch-here < 3 [ set hidden? true ]
    ; else commands
    [ set hidden? false ]
    )
  ]
end

; @function name: load-altitude
; Loads altitude data of each terrain from csv file.
to load-altitude
  file-open "Asian Map Altitude.csv"
  let i 0
  while [not file-at-end?] [
    let j 0
    foreach(csv:from-row file-read-line) [
      ;ask patches
      n -> ask patches [
        if pycor = i and pxcor = j [
          set altitude n
        ]
      ]
      set j j + 1
    ]
    set i i - 1
  ]
end

; @function name: load-temperature
; Loads temperature data of each terrain from csv file.
to load-temperature
  file-open "Asian Map Tempurature.csv"
  let i 0
  while [not file-at-end?] [
    let j 0
    foreach(csv:from-row file-read-line) [
      ;ask patches
      n -> ask patches [
        if pycor = i and pxcor = j [
          set temperature n
        ]
      ]
      set j j + 1
    ]
    set i i - 1
  ]
end

; @function name: load-precipitation
; Loads precipitation data of each terrain from csv file.
to load-precipitation
  file-open "Asian Map Precipitation.csv"
  let i 0
  while [not file-at-end?] [
    let j 0
    foreach(csv:from-row file-read-line) [
      ;ask patches
      n -> ask patches [
        if pycor = i and pxcor = j [
          set precipitation n
        ]
      ]
      set j j + 1
    ]
    set i i - 1
  ]
end

; @function name: load-river
; Loads river data of each terrain from csv file.
to load-river
  file-open "Asian Map River.csv"
  let i 0
  while [not file-at-end?] [
    let j 0
    foreach(csv:from-row file-read-line) [
      ;ask patches
      n -> ask patches [
        if pycor = i and pxcor = j [
          set river n
        ]
      ]
      set j j + 1
    ]
    set i i - 1
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
245
10
1533
659
-1
-1
10.0
1
10
1
1
1
0
0
0
1
0
127
-63
0
1
1
1
ticks
30.0

BUTTON
10
185
108
230
Initialize
initialize
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
118
19
228
64
color_by
color_by
"Satellite" "Altitude" "Temperature" "Precipitation" "River"
0

BUTTON
116
185
228
231
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
12
19
110
102
Load Map
load-map
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
10
238
228
388
Population
Year
Population
0.0
8000.0
0.0
1000.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count persons"

PLOT
10
396
228
546
Cultivated
Year
Area
0.0
8000.0
0.0
1000.0
true
false
"" ""
PENS
"default" 1.0 0 -4079321 true "" "plot count patches with [ cultivated > 0 ]"

SLIDER
11
107
228
140
Latitude
Latitude
22
30
28.0
1
1
NIL
HORIZONTAL

SLIDER
10
145
228
178
Longitude
Longitude
105
120
115.0
1
1
NIL
HORIZONTAL

SWITCH
118
69
228
102
Show-People
Show-People
0
1
-1000

@#$#@#$#@
## PROGRAM DESCRIPTION

Author: Joshua Allen, Yujin Yoshimura
Course: CMPS 4553 Computational Method
Instructor: Dr. Tina Johnson
Final Project

This program simulates how rice cultivation started and spread in a region of Asia from ancient times.

## WHY RICE?

Rice is a crop that is widely grown in the world, especially in Asia. Rice can be cultivated either in a dry soil (upland rice) or in a paddy field (rice field). Rice fields have advantages over upland rice, such that rice fields allow continuous cropping of rice without replant failure, whereas upland rice has replant failure. The biggest obstacle for making paddy fields is securing large amounts of water. Some regions of Asia have climates with large amounts of rainfall due to the Tibetan plateau, which fulfills the requirements for rice cultivation. Rice is also a very efficient crop in terms of production per land area, which means rice cultivation can sustain a larger population than other crops. This explains why China and India have had huge populations historically.

## STEPS TO USE

1. Click "Load Map".
2. Click "Initialize".
3. Click "Go".

## MORE ABOUT THE INTERFACES

There are 5 versions of maps - Satellite, Altitude, Temperature, Precipitation, River. Each maps can be displayed by choosing from "Color By". This will help you understand the geographic barriers for rice cultivation to spread.

You may also choose whether to show people or not, by turning on or off the "Show People" switch.

Finally, You may choose which part of Southern China to start the rice cultivation, by choosing "Latitude" and "Longitude" sliders.

## THINGS TO NOTICE

Rice can be cultivated in warm to hot climate with plenty of water resources. The technology of rice cultivation may cross ocean, as trading had been active in this region. One more point that you may pay attention is that the population being supported by rice cultivation.

## CREDITS AND REFERENCES

Ricepedia
http://ricepedia.org/

World Bank Data
https://data.worldbank.org/

NOAA Climate.gov
https://www.climate.gov/maps-data
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
