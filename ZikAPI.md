"API" for Parrot Zik headphones

GET /api/audio/sound_effect/get

<sound_effect
enabled="true"
room_size="silent"
angle="120">

SET /api/audio/sound_effect/room_size/set?arg=silent

silent
living
jazz
concert

SET /api/audio/sound_effect/angle/set?arg=30

30
60
90
120
150
180 (not for silent room?)

GET /api/audio/equalizer/get

<equalizer
enabled="false"
preset_id="1"
preset_value="-3.00,-2.00,3.00,3.00,2.00,-1.00,-1.00">

GET /api/audio/equalizer/presets_list/get

<preset
id="0"
name="Vocal"
value="-3.00,-3.00,3.00,3.00,0.00,2.00,0.00">

SET /api/audio/equalizer/preset_id/set?arg=0

0
1
2
3
4
5
6
