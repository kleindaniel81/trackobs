{smcl}
{* *! version 3.1.0  09jul2024}{...}
{cmd:help trackobs}
{hline}

{title:Title}

{p 5 18}
{cmd:trackobs} {hline 2} Keep track of number of observations


{...}
{title:Syntax}

{p 5 8}
Basic syntax

{p 8 18 2}
{cmd:trackobs set} 
[ {cmd:,} {opt reset} ]

{p 8 18 2}
{cmd:trackobs} 
{cmd::} {it:command}

{p 8 18 2}
{cmd:trackobs report}

{p 8 18 2}
{cmd:trackobs clear}


{p 4 10 2}
where {it:command} is a Stata command


{p 5 8}
Advanced syntax

{p 8 18 2}
{cmd:trackobs}
{cmd:set group}
{c -(}
{cmd:_n} {c |} {varlist}
{c )-}

{p 8 18 2}
{cmd:trackobs} 
[[ {cmd:,} {opt label(string)} [{opt s}]{opt return} ] {cmd::} ] 
[ {it:command} ]

{p 8 18 2}
{cmd:trackobs report} 
[ {helpb using} {it:{help filename}} ]

{p 8 18 2}
{cmd:trackobs saving} 
{it:{help filename}} 
[ {cmd:,} {opt replace} ]


{...}
{title:Description}

{pstd}
{cmd:trackobs} 
keeps a record of the number of observations in the current dataset. 
The basic syntax diagram represents the typical workflow: 


{pstd}
{cmd:trackobs set} 
specifies that the number of observations be recorded. 
Technically, the command defines a characteristic, 
{cmd:_dta[trackobs_counter]}, 
that is used by {cmd:trackobs}; see {helpb char}. 

{pstd}
The advanced syntax

{phang2}
{cmd:trackobs set group} {c -(} {cmd:_n} {c |} {varlist} {c )-}

{pstd}
specifies the variables that together define observations;
{cmd:_n} (the default) 
denotes that each row of the dataset defines an observation. 
The advanced syntax requires the datset be 
{cmd:trackobs set}
before.


{pstd}
{cmd:trackobs}, 
when specified as a prefix, 
records the number of observations before {it:command} is executed 
and after {it:command} has concluded; 
{it:command} itself is recorded, too. 

{pstd}
The advanced prefix syntax is 

{phang2}
{cmd:trackobs} [[ {cmd:,} {opt label(string)} [{opt s}]{opt return} ] 
{cmd::} ] [ {it:command} ]

{pstd}
where the colon following 
{cmd:trackobs} 
must be typed if options are specified 
or if {it:command} is also a {cmd:trackobs} subcommand. 
Technically, {cmd:trackobs} defines a characteristic, 
{cmd:_dta[trackobs_}{it:i}{cmd:]} (see {help char}),
where {it:i} is the counter that is stored in {cmd:_dta[trackobs_counter]}. 


{pstd}
{cmd:trackobs report} 
lists the recorded commands and associated numbers of observations, 
optionally from {it:filename}. 


{pstd}
{cmd:trackobs clear} 
discards all records. 
Records are saved with the dataset when they are not cleared. 
Technically, the command deletes the contents of all 
{cmd:_dta[trackobs_}{it:*}{cmd:]} characteristics 
set by {cmd:trackobs} ; see {help char}. 


{pstd}
{cmd:trackobs saving} 
saves the recorded commands 
and associated numbers of observations to a Stata dataset. 
This subcommand is useful when you want to manipulate the recorded information. 
Regarding workflow, {cmd:trackobs saving} is optional; 
{cmd:trackobs} results are saved along with the dataset 
when they are not cleared, but see Remarks below.


{pstd}
{cmd:trackobs}
typed without arguments displays the current settings.


{...}
{title:Remarks}

{pstd}
When datasets are combined using 
{help merge}, 
{help append}, 
{help joinby},
or similar commands, 
{cmd:trackobs}
discards {cmd:_dta[trackobs_}{it:*}{cmd:]} characteristics
from the so-called using-datasets. 

{pstd}
Some commands, such as {helpb preserve} and {helpb restore}, 
do not work correctly when they are prefixed with {cmd:trackobs}. 

{pstd}
In rare situations, 
{cmd:trackobs} 
might fail unexpectedly when {it:command} modifies {cmd:_dta} characteristics; 
see {helpb char}. 


{...}
{title:Options}

{phang}
{opt reset} 
clears previous {cmd:trackobs} records (technically: characteristics), 
including the {cmd:group} variables,
and resets the counter.  

{phang}
{opt label(string)}
defines a label (up to 80 characters) for the respective {it:command}, if any.
When {it:command} is not specified, 
the current number of observations are stored together with {it:string}.

{phang}
[{opt s}]{opt return} 
returns the number of observations before {it:command} was executed, 
the number of observations when {it:command} concluded, 
the command label, if any,
and {it:command} itself 
in {cmd:s()} or {cmd:r()}. 
When neither {opt label()} nor {it:command} are specified, 
the last recorded command, 
its label, if any, 
and the associated numbers of observations 
are returned.

{phang}
{opt replace} 
allows {cmd:trackobs} to overwrite {it:filename}.


{...}
{title:Examples}

{pstd}
Basic example

{phang2}{cmd:. trackobs set}{p_end}
{phang2}{cmd:. trackobs : sysuse auto}{p_end}
{phang2}{cmd:. trackobs : drop if foreign}{p_end}
{phang2}{cmd:. trackobs report}{p_end}

{pstd}
Continuation of the above

{phang2}{cmd:. trackobs , label(above avg. mpg) : keep if mpg > 20}{p_end}
{phang2}{cmd:. trackobs set group rep78}{p_end}
{phang2}{cmd:. trackobs , label(rep78 defines observations now)}{p_end}
{phang2}{cmd:. trackobs : drop if rep78 >= .}{p_end}
{phang2}{cmd:. keep if weight < 3368}{p_end}
{phang2}{cmd:. trackobs , label(rep78 with below avg. weight)}{p_end}
{phang2}{cmd:. trackobs report}{p_end}

{pstd}
Clean up

{phang2}{cmd:. trackobs clear}{p_end}


{...}
{title:Saved results}

{pstd}
{cmd:trackobs} 
stores its results in characteristics; see {helpb char}. 
Currently, the command defines and modifies the following characteristics:

        {cmd:_dta[trackobs_counter]}
        {cmd:_dta[trackobs_}{it:i}{cmd:]}

{pstd}
Do not change the contents of these characteritics, 
except by using {cmd:trackobs}.


{pstd}
{cmd:trackobs} 
with option {opt sreturn}
saves the following in {cmd:s()}:

{pstd}
Macros{p_end}
{synoptset 16 tabbed}{...}
{synopt:{cmd:s(N_was)}}number of observations before {it:command} was executed
{p_end}
{synopt:{cmd:s(N_now)}}number of observations when {it:command} concluded
{p_end}
{synopt:{cmd:s(label)}}label, if any, associated with {it:command}
{p_end}
{synopt:{cmd:s(cmdline)}}{it:command} as typed
{p_end}

{pstd}
{cmd:trackobs} 
with option {opt return}
saves the following in {cmd:r()}:

{pstd}
Scalars{p_end}
{synoptset 16 tabbed}{...}
{synopt:{cmd:r(N_was)}}number of observations before {it:command} was executed
{p_end}
{synopt:{cmd:r(N_now)}}number of observations when {it:command} concluded
{p_end}

{pstd}
Macros{p_end}
{synoptset 16 tabbed}{...}
{synopt:{cmd:r(label)}}label, if any, associated with {it:command}
{p_end}
{synopt:{cmd:r(cmdline)}}{it:command} as typed
{p_end}


{title:Acknowledgments}

{pstd}
{cmd:trackobs} 
was first published on 
{browse "https://www.statalist.org/forums/forum/general-stata-discussion/general/1452888-higher-order-commands?p=1452933#post1452933":Statalist}
in response to an anonymous post.


{title:Support}

{pstd}
Daniel Klein{break}
klein.daniel.81@gmail.com


{title:Also see}

{psee}
Online: {helpb log}, {helpb char}, {helpb list}
{p_end}
