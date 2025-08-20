# Booty Poison Twister #

## What is Booty Poison Twister? ##
Addon created for TurtleWoW. 
Lightweight poison timers for rogues. Due to limitation of 1.12 Client there is no possibility to track your own poisons on enemy target. 
This addon tracks poison 'casts' on target by utilizing UNIT_CASTEVENT events. Addon is not bullet proof. If you change target, poison is resisted or dispelled addon timer/stacks will not be adjusted.

Mostly useful on PvE encounters if you want to twist poisons.

## Requirement ##
TurtleWoW Client
Addons:
    - SuperWoW

## Usage ##
### Commands: ###
/bpt or /booty {show  | lock | config | test }
 - show - toggle show/hide the timers
 - lock - toggle lock/unlock the timers position
 - config - toggle on/off the options menu
 - test - run fake timers
 - shake - shake yo Booty!

## Bug report ##
Please report any bugs through github issues.
Known bugs:
    - There is some issue with saving window placement after using scale option. If it happens just move timers window again and relog.