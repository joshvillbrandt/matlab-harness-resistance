function [ resistance ] = harnessResistance( gauge, strands, length, spec )
%HARNESSRESISTANCE Builds harness resistance estimate in Ohms.
%   harnessResistance( gauge, strands, length, spec )
%    gauge (AWG)
%    strands (non-dimensional)
%    length (ft)
%    spec (33 or 44)
%
%   The resistance per foot calculations come from the M22759/33 and
%   M22759/44 specifications. It is common to choose /33 for 20AWG wire and
%   smaller for the higher tensile strength and /44 for 18AWG wire and
%   larger for the lower contact resistance.
%   Contact resistances (one at each side of a harness per strand) is given
%   as worst case resistance for D38999-style connectors. MIL-DTL-38999
%   specifies contacts shall conform to AS39029, which references MIL-DTL-
%   22520 for the voltage drop. See this page for more information:
%   http://www.glenair.com/interconnects/mildtl38999/pdf/a/contact_
%   performance_spec.pdf

% resistance lookup tables [AWG, ohms/ft] (at 20 degrees C / 68 degrees F)
persistent spec33 spec44 specOnline specContact;
if isempty(spec33)
    spec33 = [20, 0.0107; 22, 0.0175; 24, 0.0284; 26, 0.0448; 28, 0.0744; 30, 0.1174];
    spec44 = [12, 0.00190; 14, 0.00288; 16, 0.00452; 18, 0.00579; 20, 0.00919; 22, 0.0151; 24, 0.0243; 26, 0.0384; 28, 0.0638];
    specOnline = [0, 0.0000983; 2, 0.000156; 4, 0.000249; 6, 0.000395; 8, 0.000628; 10, 0.000999]; % http://www.powerstream.com/Wire_Size.htm
    specContact = [12, 0.0050; 16, 0.0085; 20, 0.0120; 22, 0.0283]; % must be ordered from low number (12) to high number (22)
end

% check inputs
if nargin < 3
	error('harnessResistance:inputCount', 'This function requires at least three arguments. Should be: harnessResistance(gauge(AWG), strands, length(ft)[, spec(33 or 44)])');
end

% add prefered spec if needed
if nargin < 4
    if gauge >= 20
        spec = 33;
    elseif gauge >= 12
        spec = 44;
    else
        spec = 0;
    end
end

% check for resistance in spec
if spec == 33 && ismember(gauge, spec33(:,1))
    ohmsPerFoot = interp1(spec33(:,1), spec33(:,2), gauge);
elseif spec == 44 && ismember(gauge, spec44(:,1))
    ohmsPerFoot = interp1(spec44(:,1), spec44(:,2), gauge);
elseif spec == 0 && ismember(gauge, specOnline(:,1))
    ohmsPerFoot = interp1(specOnline(:,1), specOnline(:,2), gauge);
else
    error('harnessResistance:wireSpec', ['The gauge you requested (' num2str(gauge) 'AWG) was not found in the wire spec (M22759/' num2str(spec) ').']);
end

% contact resistance (this should not extrapolate)
if ismember(specContact(:,1),gauge)
    ohmsPerContact = interp1(specContact(:,1), specContact(:,2), gauge);
elseif gauge < min(specContact(:,1))
    ohmsPerContact = specContact(1,2);
	warning('harnessResistance:contactSpec', ['The gauge you requested (' num2str(gauge) 'AWG) was not found in the contact spec.']);
else
    [~, nextBiggestGauge] = ismember(1, specContact(:,1) <= gauge);
    ohmsPerContact = specContact(nextBiggestGauge, 2);
end

% actual resistance calculation in ohms
resistance = (ohmsPerFoot*length + 2*ohmsPerContact)/strands;

end

