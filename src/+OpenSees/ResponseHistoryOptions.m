classdef ResponseHistoryOptions < handle

properties
    damping_ModeA   = 1
    damping_ModeB   = 3
    damping_RatioA  = 0.025
    damping_RatioB  = 0.025

    constraints = OpenSees.ConstraintsOptions();
    test = OpenSees.TestOptions('tolerance',[1e-5,5e-5,1e-4]);
    algorithm = OpenSees.AlgorithmOptions();
end

methods

function set.constraints(obj,constraints)
    assert(isa(constraints,'ConstraintsOptions'), 'constraints must be a ConstraintsOptions object')
    obj.constraints = constraints;
end
function set.test(obj,test)
    assert(isa(test,'TestOptions'), 'test must be a TestOptions object')
    obj.test = test;
end
function set.algorithm(obj,algorithm)
    assert(isa(algorithm,'AlgorithmOptions'), 'algorithm must be a AlgorithmOptions object')
    obj.algorithm = algorithm;
end

end

end
