# Using ProjectSimulator with the MAcroHub gem


    require 'macrohub'
    require 'projectsimulator'

    s=<<EOF
    macro: Morning welcoming announcement

    trigger: Motion detected in the kitchen
    action: Say 'Good morning'
    action: webhook entered_kitchen
      url: http://someurl/?id=kitchen
    constraint: between 7am and 7:30am

    macro: Good night announcement
    trigger: Motion detected in the kitchen
    action: Say 'Good night'
    constraint: After 10pm
    EOF


    mh = MacroHub.new(s)

    ps = ProjectSimulator::Controller.new(mh)

    $env = {time: Time.parse('7:15am')}
    $debug = true
    ps.trigger :motion, location: 'kitchen'
    #=> ["say: Good morning", "webhook: http://someurl/?id=kitchen"] 

    $env = {time: Time.parse('8:05pm')}
    ps.trigger :motion, location: 'kitchen'
    #=> []

    $env = {time: Time.parse('10:05pm')}
    ps.trigger :motion, location: 'kitchen'
    #=> ["say: Good night"] 


In the above example a couple of macros are created in plain text. The 1st macro is triggered when there is motion detected in the kitchen between 7am and 7:30am. If successful it returns the message 'say: Good morning'.

The 2nd macro is triggered when there is motion detected in the kitchen after 10pm. If successful it returns the message 'say: Good night'.

The ProjectSimulator facilitates the execution of triggers, validation of constraints and invocation of actions in cooperation with the MacroHub gem.

## Resources

* macrohub https://rubygems.org/gems/macrohub

macro macrohub gem simulator project projectsimulator macrodroid

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
