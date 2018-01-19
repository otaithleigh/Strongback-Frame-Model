classdef ConstraintsOptions < handle

properties
    type = 'Transformation';    % constraints type
    alphaS                      % penalty value/Lagrange multiplier on single-point constraints
    alphaM                      % penalty value/Lagrange multiplier on multi-point constraints
end
properties (Hidden, Constant)
    validConstraints = {'Plain','Penalty','Transformation'};
end

methods
%--------------------------------- Constructor --------------------------------%
function obj = ConstraintsOptions(varargin)
    props = properties(obj);
    if nargin > 2*length(props)
        error('Too many input arguments')
    end
    if mod(nargin,2) ~= 0
        error('Unbalanced keyword list')
    end
    for i = 1:2:nargin
        argname = varargin{i};
        argval  = varargin{i+1};
        check = strcmp(props,argname);
        if any(check)
            obj.(props{check}) = argval;
        end
    end
end

%--------------------------------- Set methods --------------------------------%
function set.type(obj,typein)
    assert(ischar(typein),'Constraints type must be a character vector');
    check = strcmpi(typein,obj.validConstraints);
    assert(any(check),'Unknown constraints type: %s',typein);
    obj.type = obj.validConstraints{check};  % Ensure capitalization is correct
end

function set.alphaS(obj,alpha)
    assert(isnumeric(alpha) && isscalar(alpha),'alphaS must be a scalar number')
    obj.alphaS = alpha;
end

function set.alphaM(obj,alpha)
    assert(isnumeric(alpha) && isscalar(alpha),'alphaM must be a scalar number')
    obj.alphaM = alpha;
end

%--------------------------------- Print arguments ----------------------------%
function str = writeArgs(obj)
    switch obj.type
    case {'Penalty', 'Lagrange'}
        str = sprintf('%s %g %g', obj.type, obj.alphaS, obj.alphaM);
    case {'Plain', 'Transformation'}
        str = sprintf('%s', obj.type);
    end
end

end

end
