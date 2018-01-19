aircraft.livery.init("Aircraft/Yak-53/Models/Liveries");

# $Id$
#
# Nasal script to print errors to the screen when aircraft exceed design limits:
#  - extending flaps above maximum flap extension speed
#  - exceeding Vna

var checkFlaps = func(n) {
  if (!n.getValue())
    return;

  var airspeed = getprop("instrumentation/airspeed-indicator/true-speed-kt");
  var max_flaps = getprop("limits/max-flap-extension-speed");

  if ((max_flaps != nil) and (airspeed > max_flaps))
  {
    screen.log.write("Flaps extended above maximum extension speed and destroyed!");
    setprop("control/flaps-not-crash", 0);
    setprop("control/flaps1", 0);
    Flaps_set();    
    setprop("control/flaps1", 1);
  }
}

# Set the listeners
setlistener("controls/flight/flaps", checkFlaps);

#Check VNE

var checkGandVNE = func {
  if (getprop("sim/freeze/replay-state"))
    return;

  var airspeed = getprop("instrumentation/airspeed-indicator/true-speed-kt");
  var vne      = getprop("limits/vne");

  if ((airspeed != nil) and (vne != nil) and (airspeed > vne))
  {
    setprop("control/canopy-not-crash", 0);
    setprop("controls/canopy/canopy-pos-norm", 1);
  }
  else
  {
    settimer(checkGandVNE, 2);
  }
}

checkGandVNE();


#Amper min/max 
var Amper_set = func {

var bus = getprop("systems/electrical/outputs/bus");
var rpm = getprop("engines/engine[0]/rpm");

if((bus != nil) and (rpm != nil) and (bus>27) and (rpm>975))
{
setprop("control/amper",
-7-0.23*getprop("systems/electrical/outputs/gear")
-0.345*getprop("systems/electrical/outputs/eng-instr-1")
-0.345*getprop("systems/electrical/outputs/nav-com-1")
-0.23*getprop("systems/electrical/outputs/ann")
-0.29*getprop("systems/electrical/outputs/pitot-heat")
-12*getprop("controls/lamp-test")
-18*getprop("control/fueltest"));
settimer(Amper_set,0.25);
}
else
{
setprop("control/amper",
0.2*getprop("systems/electrical/outputs/gear")+
0.3*getprop("systems/electrical/outputs/eng-instr-1")+
0.3*getprop("systems/electrical/outputs/nav-com-1")+
0.2*getprop("systems/electrical/outputs/ann")+
0.25*getprop("systems/electrical/outputs/pitot-heat")+
10*getprop("controls/lamp-test")+
15*getprop("control/fueltest"));
settimer(Amper_set,0.25);
}
}

Amper_set();




#Engine stop 
var StopEng = func {

var tempoil = getprop("engines/engine/oil-temperature-degf");
var rpm = getprop("engines/engine[0]/rpm");

if((tempoil != nil) and (rpm != nil) and (tempoil<104) and (rpm>2850))
{
setprop("controls/engines/engine/magnetos", 0);
setprop("control/engstop", 1);
settimer(StopEng, 15);
}
else
{
settimer(StopEng, 25);
}
}

StopEng();


#Engine stop2 
var StopEng2 = func {

var minmaxg = getprop("fdm/jsbsim/accelerations/n-pilot-z-norm[0]");
var minmaxg2 = getprop("fdm/jsbsim/accelerations/n-pilot-x-norm[0]");
var minmaxg3 = getprop("fdm/jsbsim/accelerations/n-pilot-y-norm[0]");

if( ((minmaxg != nil) and ((minmaxg<-10) or (minmaxg>7))) 
or ((minmaxg2 != nil) and ((minmaxg2<-3) or (minmaxg2>3))) 
or ((minmaxg3 != nil) and ((minmaxg3<-3) or (minmaxg3>3))) )
{
setprop("controls/engines/engine/magnetos", 0);
setprop("control/engstop2", 1);
}
else
{
settimer(StopEng2, 0.1);
}
}

StopEng2();


#Gear crash

var checkgearG = func {

  var maxg = getprop("fdm/jsbsim/accelerations/n-pilot-z-norm[0]");
  var maxg2 = getprop("fdm/jsbsim/accelerations/n-pilot-x-norm[0]");
  var speed = getprop("velocities/airspeed-kt");  
  var wow0 = getprop("gear/gear[0]/wow");
  var wow1 = getprop("gear/gear[1]/wow");
  var wow2 = getprop("gear/gear[2]/wow");  
  
  if ( ((maxg<-3 or maxg2>3) or speed>92) and ((wow0==1) or (wow1==1) or (wow2==1)))
  {
    setprop("control/gear-not-crash", 0);
    setprop("controls/gear/gear-down", 0);
    setprop("controls/engines/engine/magnetos", 0);
    setprop("control/engstop2", 1);
  }
  else
  {
    settimer(checkgearG, 0.1);
  }
}

checkgearG();


#Canopy routines

toggle_canopy = func {
  if(getprop("controls/canopy/canopy-pos-norm") > 0) {
    interpolate("controls/canopy/canopy-pos-norm", 0, 1.25);
  } else {
    interpolate("controls/canopy/canopy-pos-norm", 1, 1.25);
  }
}


#g-meter min/max needles

registerTimer = func {
                     settimer(gmeterUpdate, 0.125);
                     }

flag = 0;
done = 0;
initialized = 0;

gmeterUpdate = func {

    GCurrent = props.globals.getNode("fdm/jsbsim/accelerations/n-pilot-z-norm[0]").getValue();

    if(!initialized) { 
     props.globals.getNode("fdm/jsbsim/accelerations/pilot-gmin[0]", -1).setDoubleValue(1);
     props.globals.getNode("fdm/jsbsim/accelerations/pilot-gmax[0]", -1).setDoubleValue(1);
     initialized = 1;
     }

    GMin1 = props.globals.getNode("fdm/jsbsim/accelerations/pilot-gmin[0]").getValue();
    GMax1 = props.globals.getNode("fdm/jsbsim/accelerations/pilot-gmax[0]").getValue();


    if(GCurrent < 1 and GCurrent < GMin1){setprop("fdm/jsbsim/accelerations/pilot-gmin[0]", GCurrent);}
    else {if(GCurrent > GMax1){setprop("fdm/jsbsim/accelerations/pilot-gmax[0]", GCurrent);}}
    
    registerTimer();

}


#fire up timers
registerTimer ();

 
setprop("engines/engine/fuel-flow-gph-ind", 0);
    
FP_set = func {
if(getprop("controls/engines/engine/pump")==0)
{setprop("engines/engine/fuel-flow-gph-ind",getprop("engines/engine/fuel-flow-gph-ind")+ 20);}
else{ }
};

  
Gear_set = func {
if(getprop("controls/gear/gear-down")==0)
{setprop("controls/gear/gear-down",getprop("control/gear-down2"));}
else{ }
};

Gear1_set = func {
if(getprop("control/pnevmo")==1)
{setprop("controls/gear/gear-down",getprop("control/gear-down1"));}
else{ }
};

Flaps_set = func {
if(getprop("control/pnevmo")==1)
{setprop("controls/flight/flaps",getprop("control/flaps1"));}
else{ }
};

Magneto_set = func {
if(getprop("systems/electrical/outputs/ign")>21)
{setprop("controls/engines/engine/magnetos",getprop("control/magneto"));}
else{setprop("controls/engines/engine/magnetos", 0)}
};


Starter_set = func {
if(getprop("control/pnevmo")==1 and getprop("systems/electrical/outputs/ign")>21)
{setprop("controls//engines/engine/starter",getprop("control/starter1"));}
else{ }
};


  
#radio com1 / chatter

   setprop("instrumentation/comm/frequencies/select100", 9);  
   setprop("instrumentation/comm/frequencies/select1", 20);
   setprop("instrumentation/comm/frequencies/select2", 0);
   setprop("instrumentation/comm/frequencies/selected-mhz", 127.500);
   
freq_set = func {setprop("instrumentation/comm/frequencies/selected-mhz", 
                 getprop("instrumentation/comm/frequencies/select100")+118+
                 0.025*getprop("instrumentation/comm/frequencies/select1"))}; 
                 
   setprop("systems/electrical/outputs/nav-com-1",0.1);   
   setprop("instrumentation/comm/volume-set", 0.4);    
   setprop("instrumentation/comm/volume", 0);    
   setprop("sim/sound/chatter/volume", 0);    

vol_set = func {
if(getprop("systems/electrical/outputs/bus")>21)
{setprop("instrumentation/comm/volume", getprop("instrumentation/comm/volume-set"));}
else{ }
};

chvol_set = func {
if(getprop("systems/electrical/outputs/bus")>21)
{setprop("sim/sound/chatter/volume", getprop("instrumentation/comm/volume-set"));}
else{ }
};

vol_Mset = func {
if(getprop("systems/electrical/outputs/nav-com-1")>21)
{setprop("instrumentation/comm/volume", getprop("instrumentation/comm/volume-set"));}
else{ }
};

chvol_Mset = func {
if(getprop("systems/electrical/outputs/nav-com-1")>21)
{setprop("sim/sound/chatter/volume", getprop("instrumentation/comm/volume-set"));}
else{ }
};

                 
#chronometr start
    setprop("sim/time/chronom-sec0", 0);

chron_start0 = func {setprop("sim/time/chronom-sec0", getprop("sim/time/elapsed-sec"))}; 

                 