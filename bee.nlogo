extensions [csv]
; final version working
;; Global Variables
globals [
  land
  food-distribution
  numTurtles
  numParasites
  temperature
  flowerPop
  season
  year
  annualParasites
  annualFlowers
  annualIslandFlowers
  crlf
  JanTemp
  FebTemp
  MarTemp
  AprTemp
  MayTemp
  JunTemp
  JulTemp
  AugTemp
  SepTemp
  OctTemp
  NovTemp
  DecTemp

  data
  rain
  isl1
  isl2
]

;; Entities

;; Patch Variables
patches-own[
  isEggs
  evolve
]

;; Flower Variables
breed [flowers flower]
flowers-own[state]

;; Island Flower Variables
breed [islandFlowers islandFlower]
islandFlowers-own[state]


;; Egg Variables
breed [eggs egg]
eggs-own[
  age
  sex
  posX
  posY
]

;; Bee Variables
breed [bees bee]
bees-own [
  age
  sex
  energy
  isQueen
  hasParasite
  survivalPr
  posX
  posY
  hibernate
]

;; Parasite Variables
breed [parasites parasite]
parasites-own[
  age
  survivalPr

]


to setup
  ;; set up map
  clear-all
  set crlf (word "\r\n")
  import-pcolors "scot.jpg"
  ask patches[if pcolor < 200 and pcolor > 50 [set pcolor blue]]
  ask patches[if pcolor < 105 [set pcolor green]]
  set year 2023

  ;; set up monitor variables
  set land count patches with [pcolor = green]
  set numTurtles count bees
  set season "Winter"
  set JanTemp -1
  set FebTemp 1
  set MarTemp 7
  set AprTemp 12
  set MayTemp 17
  set JunTemp 22
  set JulTemp 24
  set AugTemp 23
  set SepTemp 19
  set OctTemp 13
  set NovTemp 5
  set DecTemp 2

  file-close-all ; Close any files open from last run
  file-open "netLogoInput.csv"

  reset-ticks
end

;; initialize bee and parasite numbers from first spring
to init
  ;; set up bees
  ;;ask n-of 50 patches with [ pcolor = green][sprout-bees 1 [set color yellow set shape "bug"]] ; sproit workers
  ask n-of 30 patches with [ pcolor = green and pycor > 10][sprout-bees 1 [set color blue set shape "bug" set isQueen 1]] ;sprout queens which are blue

  ; Stornoway
  ask patches with [ pcolor = green and pxcor = -30 and pycor = 34][sprout-bees 1 [set color blue set shape "bug" set isQueen 1]]
  ;ask patches with [ pcolor = green and pxcor = -30 and pycor = 35][sprout-bees 1 [set color blue set shape "bug" set isQueen 1]]
  ;ask patches with [ pcolor = green and pxcor = -31 and pycor = 29][sprout-bees 1 [set color blue set shape "bug" set isQueen 1]]
  ;ask patches with [ pcolor = green and pxcor = -36 and pycor = 28][sprout-bees 1 [set color blue set shape "bug" set isQueen 1]]

  ; Shetland
  ask patches with [ pcolor = green and pxcor = 17 and pycor = 59][sprout-bees 1 [set color blue set shape "bug" set isQueen 1]]
  ;ask patches with [ pcolor = green and pxcor = 17 and pycor = 51][sprout-bees 1 [set color blue set shape "bug" set isQueen 1]]
  ;ask patches with [ pcolor = green and pxcor = 23 and pycor = 54][sprout-bees 1 [set color blue set shape "bug" set isQueen 1]]

  ; Isle of Mull
  ask patches with [ pcolor = green and pxcor = -41 and pycor = 18][sprout-bees 1 [set color blue set shape "bug" set isQueen 1]]
  ;ask patches with [ pcolor = green and pxcor = -42 and pycor = 12][sprout-bees 1 [set color blue set shape "bug" set isQueen 1]]


  ask bees [set energy 100]
  set annualParasites false
  set annualFlowers false
  set annualIslandFlowers false


end

;; Process Overview and Scheduling
to go
  ;if ticks > 1460 [outPop "dailyBeePop.csv"]
  ;if ticks = 1825 [  stop ]
  if file-at-end? [ stop]
  set data csv:from-row file-read-line
  set temperature first data
  set rain item 1 data
  if ticks mod 365 = 364 [outPop "islandPop.csv"]
  if ticks = 60 [init] ;;set up bees from spring

  ;main land flowers
  if temperature > 5 and annualFlowers = false [ask n-of food patches with [ pcolor = green and pycor > 10 and pxcor > -24][sprout-flowers 1 [set color pink set shape "flower" set state 600 set annualFlowers true]]]

  ;stornoway flowers
  if temperature > 5 and annualIslandFlowers = false [ask n-of 25 patches with [pcolor = green and pxcor > -38 and pxcor < -25 and pycor > 23  and pycor < 42][sprout-flowers 1 [set color blue set shape "flower" set state 3000 set annualIslandFlowers true]]]


  if temperature > 10 and annualParasites = false and (ticks mod 365 > 60) [ask n-of 7 patches with [ pcolor = green and pycor > 10][sprout-parasites 1 [set color red set shape "bug" set annualParasites true]]]
  if ticks mod 365 = 364 [set year year + 1]
  if ticks mod 365 = 364 [set annualParasites false]
  if ticks mod 365 = 364 [set annualFlowers false]
  if ticks mod 365 = 364 [set annualIslandFlowers false]
  if ticks mod 365 = 364 [ask flowers[die]]
  ask bees [
    let close-parasites parasites in-radius 1
    if any? close-parasites [
      infectBee
    ]
  ]
  if temperature < -2 [killAll]
  bees-move
  spreadParasite
  useEnergy
  updateAge
  reproduce
  eggToBee
  set numTurtles count bees
  set numParasites count parasites
  set flowerPop count flowers
  updateTemp
  updateFlowers
  hibernation
  survive
  tick
end

to countIsland
  set isl1 count patches with [pcolor = green and pxcor > -42 and pxcor < -22 and pycor > 21  and pycor < 42 and any? bees-here]

end

to outPop [file-name]
  countIsland
  let wdata (list (list (isl1)))
  if file-exists? file-name [
    let existing-data csv:from-file file-name
    set wdata (sentence existing-data wdata)
  ]
  csv:to-file file-name wdata
end





to rainCheck
  let percentPop numTurtles * 0.1
  let y round percentPop
  if rain = 1 [ask n-of y bees [die]]

end

to killAll
  ask n-of (count bees * 0.9) bees [  die]
end

to updateFlowers
  ask flowers with [state <= 0][die]

end

;; Bees go into hibernation in Autumn and Come Out in spring
to hibernation
  if (ticks mod 365) > 244 [
    ask bees with [isQueen = 1 ][set hibernate 1 set color 35]
  ]
  if (ticks mod 365) = 60 [
    ask bees with [isQueen = 1 ][set hibernate 0 set color blue]
  ]
end


to infecBee
  let random-num random 10 + 1
  if random-num > 6 [ask bees [die]]

end


to survive

  if temperature <= -7 [ask bees [die]]

  if temperature <= 5 [
    ask bees with [hibernate != 1][die]
    ask flowers [die]
  ]

  if temperature >= 45 [
    ask bees [die]
  ]

  if temperature >= 40 [
    ask parasites [die]
  ]

  if temperature <= 10 [
    ask parasites [die]

  ]

end

to updateTemp
  let day (ticks mod 365)
  if day <= 31 [set season "Winter" ] ;; january
  if day >= 32 and day <= 59 [set season "Winter" ] ;; February
  if day >= 60 and day <= 90 [set season "Spring"] ;; March
  if day >= 91 and day <= 120 [set season "Spring" ] ;; April
  if day >= 121 and day <= 151 [set season "Spring" ] ;; May
  if day >= 152 and day <= 181 [set season "Summer" ] ;; June
  if day >= 182 and day <= 212 [set season "Summer" ] ;; July
  if day >= 213 and day <= 243 [set season "Summer" ] ;; August
  if day >= 244 and day <= 273 [set season "Autumn" ] ;; Sepetember
  if day >= 274 and day <= 304 [set season "Autumn" ] ;; October
  if day >= 305 and day <= 334 [set season "Autumn" ] ;; November
  if day >= 335 [set season "Winter" ] ;; December

end
to infectBee
  let random-num random 10 + 1
end


;; Evolve eggs to bees
to eggToBee
  ask eggs with [age > 10][
    ask patch-at (round posX) (round posY) [set evolve 1]

    die]
  evolveEggToBee

end

;; sub process of egg to bee
to evolveEggToBee
  ask patches with [evolve = 1 and pcolor = green][sprout-bees 2 [set shape "bug" set color yellow] sprout-bees 1 [set color blue set shape "bug" set isQueen 1]]
  ask patches with [evolve = 1][set evolve 0]
end

;; Mark where queen has laid eggs
to eggCheck
  ask bees with [isQueen = 1 and energy > 80 and temperature >= 10 and age > 30 and hibernate != 1 and (ticks mod 365) < 243][
     ask patch-at (round posX) (round posY) [set isEggs 1]
  ]
end

;; Put egg entity where queen laid egg
to reproduce
  eggCheck
  ask patches with [isEggs = 1][
    sprout-eggs 1 [set color red set shape "dot"]
    set isEggs 0
  ]
end

;; Bees use energy when they move
;; Bees gain energy when they find a flower
to useEnergy
  ask bees [set energy energy - 1]
  ask flowers [
   ask bees-here[
     set energy energy + 10
      ask flowers-here [set state state - 10]
    ]
  ]
  ask bees with [energy = 0][die]
end

;; Update age of every entity and kill entities that are out of lifespan
to updateAge
  ;; Update ages
  ask bees with [hibernate != 1] [set age age + 1]
  ask parasites [set age age + 1]
  ask eggs[set age age + 1]

  ;; Kill Old Entities
  ask bees with [isQueen != 1 and age > 28][die] ;; kill bees when they get to old
  ask bees with [isQueen = 1 and age > 50 ][die] ;; queens live longer than worker bees
  ;ask parasites with [age > 20][die] ;; kill bees when they get to old
end


;; If bees come in contact with parasite infect them
to spreadParasite
  ask parasites [
    ask bees-here [
      die
    ]
  ]
end

;; Bees Movement
to bees-move

  ask bees with [hibernate != 1] [
    wiggle
    if [pcolor] of patch-ahead 1 = green [
      forward 0.5
    ]
  ]

end

;; Bee movement subprocess
to wiggle
  right random 90
  left random 90
end
@#$#@#$#@
GRAPHICS-WINDOW
0
207
1518
1726
-1
-1
10.0
1
10
1
1
1
0
1
1
1
-75
75
-75
75
0
0
1
ticks
30.0

BUTTON
1527
649
1606
685
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1524
695
1581
740
land
land
17
1
11

MONITOR
1525
798
1620
843
Bee Population
numTurtles
17
1
11

BUTTON
1620
649
1701
687
go
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

SLIDER
1526
903
1698
936
food
food
0
1500
1150.0
1
1
NIL
HORIZONTAL

MONITOR
1621
697
1708
742
Time OF Year
season
17
1
11

MONITOR
1525
747
1610
792
Temperature
temperature
17
1
11

MONITOR
1626
798
1751
843
Parasites Population
numParasites
17
1
11

MONITOR
1525
850
1636
895
Flower Population
flowerPop
17
1
11

MONITOR
1717
697
1774
742
Year
year
17
1
11

PLOT
1539
951
1857
1188
Population
year
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "set-plot-pen-mode 1\nset-plot-x-range 2023 2073\nplotxy year numTurtles\n\n\n"

PLOT
1541
1208
1859
1411
Rainfall
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "set-plot-pen-mode 1\nset-plot-x-range 2023 2073\nplotxy year rain"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment1" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count bees</metric>
    <enumeratedValueSet variable="food">
      <value value="1150"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
