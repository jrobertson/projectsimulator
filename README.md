# Using ProjectSimulator to trigger an action

    require 'projectsimulator'

    s=<<EOF
    event: Morning welcoming announcement

    trigger: Motion detected in the kitchen
    action: Say 'Good morning'
    action: webhook entered_kitchen
    constraint: Between 8am and 10am
    constraint: On a Wednesday

    event: Good night announcement
    trigger: Motion detected in the kitchen after 10pm
    action: Say 'Good night'
    constraint: After 10pm
    EOF

    t = Chronic::parse 'Wednesday 8:32am'
    ps = ProjectSimulator::Controller.new(s, time: t, debug: true)
    ps.events[0].actions[1].url = 'http://someurl/clicked/kitchen'
    ps.trigger :motion, location: 'kitchen'

    #=> ["say: Good morning", "webhook: http://someurl/clicked/kitchen"]


The above example demonstrates the triggering of an action based on the constraints. In this case, when someone entered the kitchen, the computer would greet the visitor with an audible message of 'Good morning'. This action would only occur on a Wednesday between 8am and 10am. Additionally, a webhook would be triggered, which could alert some other service of the initial trigger.

Notes:

* Another constraint would need to be added to check that the motion was only detected once within the given time, to avoid the trigger being fired whenever there was any motion in the kitchen.

projectsimulator simulation simulation iot 

--------------------------------

# Introducing the Project Simulator gem

    require 'projectsimulator'

    s = 'turn the kitchen light on
    turn the livingroom gas_fire on
    '
    ps = ProjectSimulator::Model.new(s)
    puts ps.xml

<pre>
&lt;building1&gt;
  &lt;kitchen&gt;
    &lt;light switch='on'/&gt;
  &lt;/kitchen&gt;
  &lt;livingroom&gt;
    &lt;gas_fire switch='on'/&gt;
  &lt;/livingroom&gt;
&lt;/building1&gt;
</pre>

    ps.request 'switch the livingroom gas_fire off'
    puts ps.xml

<pre>
&lt;building1&gt;
  &lt;kitchen&gt;
    &lt;light switch='on'/&gt;
  &lt;/kitchen&gt;
  &lt;livingroom&gt;
    &lt;gas_fire switch='off'/&gt;
  &lt;/livingroom&gt;
&lt;/building1&gt;
</pre>

    ps.request 'switch the gas_fire on'
    puts ps.xml

<pre>
&lt;building1&gt;
  &lt;kitchen&gt;
    &lt;light switch='on'/&gt;
  &lt;/kitchen&gt;
  &lt;livingroom&gt;
    &lt;gas_fire switch='on'/&gt;
  &lt;/livingroom&gt;
&lt;/building1&gt;
</pre>

    ps.request 'is the gas_fire on?'
    #=> "The livingroom gas_fire is on."

## Resources 

* projectsimulator https://rubygems.org/gems/projectsimulator

home automation simulator gem projectsimulator project
