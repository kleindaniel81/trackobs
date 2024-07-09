*! version 3.1.0  09jun2024
program trackobs
    
    version 11.2
    
    gettoken subcmd : 0 , parse(" ,") quotes bind
    
    if (`"`subcmd'"' == "") {
        
        trackobs_display_settings `macval(0)'
        exit
        
    }
    
    if ( inlist(`"`subcmd'"',"set","clear","report","saving") ) {
        
        trackobs_`macval(0)'
        exit
        
    }
    
    if (`"`subcmd'"' == ",") ///
        trackobs_options `macval(0)'
    
    trackobs_chars_to_locals I group
    
    gettoken colon zero : 0 , parse(":") quotes bind
    if (`"`colon'"' == ":") ///
        local 0 : copy local zero
    
    gettoken command : 0 , quotes bind
    if inlist(`"`command'"', ///
        "preserve",          ///
        "restore",           ///
        "frame",             ///
        "frames"             ///
        )                    ///
    {
        
        display as err "`command' not supported by trackobs"
        exit 498
        
    }
    
    nobreak {
        
        trackobs_clear
        
        trackobs_count N_was `group'
        
        capture noisily break ///
            version `=_caller()' : trackobs_stata_command `macval(0)'
        local rc = _rc
        
        trackobs_count N_now `group'
        
        capture trackobs_clear
        
        forvalues i = 1/`I' {
            char _dta[trackobs_`i'] `macval(trackobs_`i')'
        }
        
        char _dta[trackobs_counter] `trackobs_counter'
        
        if ( (!`rc') | (`N_was'!=`N_now') ) {
            
            trackobs_next_i `I' `N_was' `N_now' `"`label'"' `macval(0)'
            
            trackobs_return , `return' `sreturn'
            
            mata : c_locals_2(`rc')
            
        }
        
    }
    
    exit `rc'
    
end


program trackobs_stata_command
    
    version 11.2
    
    tokenize // clear local macros 1, 2, ...
    
    version `=_caller()' : `macval(0)'
    
    mata : c_locals_1()
    
end


/*  _________________________________________________________________________
                                                         display settings  */

program trackobs_display_settings
    
    syntax // nothing expected; nothing allowed
    
    trackobs_settings I group
    
    if ("`group'" == "") ///
        local group _n
    
    display
    display as txt "trackobs counter : " as res `I'
    display as txt "trackobs group   : " as res "`group'"
    
end


/*  _________________________________________________________________________
                                                                      set  */

program trackobs_set
    
    if ( !replay() ) {
        
        trackobs_set_settings `macval(0)'
        
        trackobs_display_settings
        
        exit
        
    }
    
    syntax [ , RESET CLEAR ] // clear is retained as a synonym
    
    if (`"`: char _dta[trackobs_counter]'"' != "") {
        
        if ("`reset'`clear'" == "") {
            
            display as err "trackobs counter already set"
            exit 498
            
        }
        
        trackobs_clear
        
    }
    
    char _dta[trackobs_counter] 0
    
    trackobs_display_settings
    
end


program trackobs_set_settings
    
    trackobs_settings I // error if not set
    
    gettoken what 0 : 0 , parse(" ,") quotes bind
    
    if (`"`what'"' == "group") {
        
        gettoken _n : 0 , parse(" ,") quotes bind        
        if (`"`_n'"' != "_n") ///
            syntax varlist(max=42)
            /*
                The limit of 42 variables is arbitrary;
                cannot fit all variable names into char.
            */
        
        char _dta[trackobs_counter] `I' `varlist'
        
        exit
        
    }
    
    display as err `"`what' not recognized"'
    exit 198
    
end


/*  _________________________________________________________________________
                                                                    clear  */

program trackobs_clear
    
    syntax // nothing allowed
    
    trackobs_settings I
    
    nobreak {
        
        forvalues i = 1/`I' {
            char _dta[trackobs_`i'] // void
        }
        
        char _dta[trackobs_counter] // void
        
    }
    
end


/*  _________________________________________________________________________
                                                                   report  */

program trackobs_report
    
    syntax [ using/ ]
    
    if ("`using'" == "") {
        
        tempfile using
        trackobs_saving `"`using'"'
        
    }
    
    preserve
    
    quietly use "`using'" , clear
    
    if (`"`: char _dta[trackobs]'"' != "trackobs") {
        
        display as err "file not created by trackobs"
        exit 698
        
    }
    
    list , noobs nodotz subvarname
    
    restore
    
end


/*  _________________________________________________________________________
                                                                   saving  */

program trackobs_saving
    
    local 0 using `0'
    syntax using/ [ , REPLACE ]
    
    trackobs_chars_to_locals I
    
    preserve
    
    clear
    
    quietly {
        
        set obs `I'
        
        generate cmdline = ""
        char cmdline[varname] "Command"
        
        generate byte N_was = .z
        char N_was[varname] "Obs. was"
        
        generate byte N_now = .z
        char N_now[varname] "Obs. now"
        
        generate label = ""
        char label[varname] "Label"
        
        forvalues i = 1/`I' {
            
            gettoken N_was trackobs_`i' : trackobs_`i'
            gettoken N_now trackobs_`i' : trackobs_`i'
            gettoken label trackobs_`i' : trackobs_`i'
            
            local trackobs_`i' `macval(trackobs_`i')'
            
            replace N_was = `N_was' in `i'
            replace N_now = `N_now' in `i'
            
            replace label = `"`label'"' in `i'
            
            replace cmdline = `"`macval(trackobs_`i')'"' in `i'
            
        }
        
        capture assert (label == "") , fast
        if ( !_rc ) version 15 : drop label
        
        char _dta[trackobs] "trackobs"
        
        save `"`using'"' , `replace'
        
    }
    
    restore
    
end


/*  _________________________________________________________________________
                                                                   return  */

program trackobs_return , sclass
    
    syntax [ , SRETURN RETURN ]
    
    if ("`return'`sreturn'" == "") ///
        exit
    
    trackobs_settings I
    
    if ( !`I' ) ///
        exit
    
    local trackobs_I : char _dta[trackobs_`I']
    
    gettoken N_was trackobs_I : trackobs_I
    gettoken N_now trackobs_I : trackobs_I
    gettoken label trackobs_I : trackobs_I
    
    if ("`sreturn'" == "sreturn") {
        
        sreturn clear
        sreturn local cmdline `macval(trackobs_I)'
        sreturn local label   `"`label'"'
        sreturn local N_now   `N_now'
        sreturn local N_was   `N_was'
        
    }
    
    if ("`return'"  != "")  ///
        trackobs_return_r `N_was' `N_now' `"`label'"' `macval(trackobs_I)'
    
end


program trackobs_return_r , rclass
    
    gettoken N_was 0 : 0
    gettoken N_now 0 : 0
    gettoken label 0 : 0
    
    return scalar N_now = `N_now'
    return scalar N_was = `N_was'
    return local  cmdline `macval(0)'
    return local  label   `"`label'"'
    
end


/*  _________________________________________________________________________
                                                                utilities  */

    /*  _________________________________  trackobs options  */

program trackobs_options
    
    gettoken 0 zero : 0 , parse(":") quotes bind
    
    syntax            ///
    [ ,               ///
        SRETURN       ///
        RETURN        ///
        LABEL(string) ///
    ]
    
    if (`"`label'"' != "") {
        
        if (c(stata_version) >= 14) ///
            local u u
        
        capture assert (`u'strlen(`"`label'"') <= 80)
        if ( _rc ) {
            
            display as err "option label() invalid"
            exit 198
            
        }
        
    }
    
    c_local sreturn : copy local sreturn
    c_local return  : copy local return
    c_local label   : copy local label
    c_local 0       : copy local zero
    
end


    /*  _________________________________  trackobs settings  */

program trackobs_settings
    
    args lmname_I lmname_group
    
    local trackobs_settings : char _dta[trackobs_counter]
    
    gettoken I trackobs_settings : trackobs_settings
    
    capture confirm integer number `I'
    if ( !_rc ) ///
        capture assert (`I' >= 0)
    
    if ( _rc ) {
        
        display as err "trackobs counter not set"
        exit 499
        
    }
    
    if ("`lmname_I'" != "") ///
        c_local `lmname_I' `I'
    
    if (`"`: char _dta[trackobs_`++I']'"' != "") {
        
        display as err "trackobs counter invalid"
        display as err "_dta[trackobs_`I'] already defined"
        exit 499
        
    }
    
    if ("`lmname_group'" == "") ///
        exit
    
    if (`"`trackobs_settings'"' != "") {
        
        capture noisily confirm variable `trackobs_settings' , exact
        if ( _rc ) {
            
            display as err "trackobs group invalid"
            exit 499
            
        }
        
    }
    
    c_local `lmname_group' `trackobs_settings'
    
end


    /*  _________________________________  characteristics to locals  */

program trackobs_chars_to_locals
    
    args lmname_I lmname_group
    
    if ("`lmname_group'" != "") ///
        local group group
    
    trackobs_settings I `group'
    
    forvalues i = 1/`I' {
        c_local trackobs_`i' : char _dta[trackobs_`i']
    }
    
    c_local trackobs_counter : char _dta[trackobs_counter]
    
    if ("`lmname_I'" != "") ///
        c_local `lmname_I' `I'
    
    if ("`lmname_group'" != "") ///
        c_local `lmname_group' `group'
    
end


    /*  _________________________________  count  */

program trackobs_count
    
    gettoken lmname_N 0 : 0
    local group `0' // strip leading whitespace
    
    if ("`group'" == "") ///
        local N = c(N)
    else ///
        trackobs_count_group N `group'
    
    c_local `lmname_N' `N'
    
end

program trackobs_count_group , sortpreserve
    
    gettoken lmname_N group : 0
    
    sort `group'
    tempvar first
    quietly by `group' : generate byte `first' = (_n==1)
    mata : st_local("N",strofreal(colsum(st_data(.,"`first'")),"%21.0g"))
    
    c_local `lmname_N' `N'
    
end


    /*  _________________________________  _dta[trackobs_i]  */

program trackobs_next_i
    
    gettoken I     0 : 0
    gettoken N_was 0 : 0
    gettoken N_now 0 : 0
    gettoken label 0 : 0 
    
    local cmdline `macval(0)' // strip leading whitespace
    
    if ( (`"`macval(cmdline)'"'=="") & (`"`label'"'=="") ) ///
        exit
    
    trackobs_settings Iwas group
    
    local ++I
    char _dta[trackobs_`I'] `N_was' `N_now' `"`label'"' `macval(cmdline)'
    char _dta[trackobs_counter] `I' `group'
    
end


/*  _________________________________________________________________________
                                                                     Mata  */

version 11.2


mata :


mata set matastrict   on
mata set mataoptimize on


void c_locals_1()
{
    string colvector lmnames
    real   scalar    i
    
    
    lmnames = st_dir("local","macro","*")
    lmnames = select(lmnames,(lmnames:!="0"))
    
    for (i=rows(lmnames); i; i--) 
        (void) _stata(
            "c_local C_LOCAL"
            + strofreal(i,"%21.0g")
            + char(32)
            + lmnames[i]
            + char(32)
            + st_local(lmnames[i])
            )
    
    (void) _stata("c_local C_LOCAL0 0 "+st_local("0"))
}


void c_locals_2(real scalar rc)
{
    string colvector C_LOCALS
    real   scalar    i
    
    
    if ( rc ) ///
        return
    
    C_LOCALS = st_dir("local","macro","C_LOCAL*")
    if (substr(st_local("C_LOCAL0"),3,.) == st_local("0"))
        C_LOCALS = select(C_LOCALS,(C_LOCALS:!="C_LOCAL0"))
    
    for (i=rows(C_LOCALS); i; i--) {
        
        C_LOCALS[i] = st_local(C_LOCALS[i])
        
        (void) _stata(
            "c_local "
            + substr(C_LOCALS[i],1,strpos(C_LOCALS[i],char(32)))
            + substr(C_LOCALS[i],strpos(C_LOCALS[i],char(32)),.)
            )
        
    }
}


end


exit


/*  _________________________________________________________________________
                                                              version history

3.1.0   09jun2024   new option -label()-
                        implies additional s() and r(results)
                        implies additional variable in -saving-
                    minor refactoring
3.0.1   08jun2024   minor refactoring
3.0.0   08jul2024   discard _dta[trackobs_*] from using datasets 
                        after -merge-, -append-, -joinby-, etc.
                    -trackobs set- now confirms next _dta[trackobs_i]
                    -trackobs set- now displays settings
                    -trackobs- without arguments now displays settings
2.0.0   07jul2024   bug fix when -trackobs- is called without arguments
                    new sub-(sub-)command -set groups-
1.4.0   05jul2024   major refactoring
                    call command under caller version
                    pass thru [c_]local macros
                    commands -restore- and -frames- not supported
                    changed return code for unsupported commands
                        r(198) -> r(498)
                    option -clear- retained but renamed -reset-
1.3.0   29aug2018   new option sreturn (not documented)
1.2.0   16jul2018   do not allow -preserve- to be used
                    do not return r() when command fails
                    code polish
1.1.1   13jul2018   minor code polish
1.1.0   13jul2018   new colon syntax for prefix
                    new option clear
                    new option return
                    new subcommand -saving-
                    new reporting routine
                    preserve characteristics accross datasets
1.0.0   11jul2018   posted on Statalist
