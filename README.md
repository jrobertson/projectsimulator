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
