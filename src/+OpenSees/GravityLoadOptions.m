classdef GravityLoadOptions < handle

properties
    constraints = OpenSees.ConstraintsOptions();
    test = OpenSees.TestOptions('tolerance',1e-6);
    algorithm = OpenSees.AlgorithmOptions('KrylovNewton');
end

methods

function obj = GravityLoadOptions(varargin)
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

function set.constraints(obj,constraints)
    assert(isa(constraints,'OpenSees.ConstraintsOptions'), 'constraints must be a ConstraintsOptions object')
    obj.constraints = constraints;
end
function set.test(obj,test)
    assert(isa(test,'OpenSees.TestOptions'), 'test must be a TestOptions object')
    obj.test = test;
end
function set.algorithm(obj,algorithm)
    assert(isa(algorithm,'OpenSees.AlgorithmOptions'), 'algorithm must be a AlgorithmOptions object')
    obj.algorithm = algorithm;
end

end

end
