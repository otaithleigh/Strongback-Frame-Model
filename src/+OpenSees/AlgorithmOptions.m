classdef AlgorithmOptions < handle

properties
    type = {'KrylovNewton'; 'Newton'; 'ModifiedNewton'};
end
properties (Hidden, Constant)
    validAlgorithms  = {'Newton','KrylovNewton','ModifiedNewton', 'SecantNewton', 'BFGS'};
end

methods
%--------------------------------- Constructor --------------------------------%
function obj = AlgorithmOptions(varargin)
    if nargin == 1 && iscell(varargin{1})
        obj.type = varargin{1};
    elseif nargin ~= 0
        obj.type = varargin(:);
    end
end

%--------------------------------- Set methods --------------------------------%
function set.type(obj,algorithm)
    for i = 1:length(algorithm)
        check = strcmpi(algorithm{i},obj.validAlgorithms);
        assert(any(check),'Unknown algorithm: %s',algorithm{i});
        algorithm{i} = obj.validAlgorithms{check};  % Ensure capitalization is correct
    end
    obj.type = algorithm;
end

end

end
