classdef ResponseHistoryOptions < handle

properties
    damping_ModeA   = 1
    damping_ModeB   = 3
    damping_RatioA  = 0.025
    damping_RatioB  = 0.025

    constraints = OpenSees.ConstraintsOptions();
    test = OpenSees.TestOptions();
    algorithm = OpenSees.AlgorithmOptions();
end

methods

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
