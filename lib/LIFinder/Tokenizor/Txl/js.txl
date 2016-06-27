% TXL Parser and Pretty-printer for standalone Javascript code
include "js.grm"


% function main
%     match [program]
%         _ [program]
% end function

function main
    replace [program]
    	    P [program]
    by
        P [normStrLit "strlit"]
	[normNum 0]
	[normId id]
end function

rule normStrLit New [stringlit]
replace [stringlit]
    name [stringlit]
    where not
    name [= New]
by
	New
end rule

rule normNum New [number]
replace [number]
    name [number]
    where not
    name [= New]
by
	New
end rule

rule normId New [id]
replace [id]
    name [id]
    where not
    name [= New]
by
	New
end rule
