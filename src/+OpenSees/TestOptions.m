classdef TestOptions < handle

properties
    % TYPE OpenSees name of the test type.
    %   Valid types are:    'NormDispIncr'
    %                       'EnergyIncr'
    type = 'NormDispIncr';

    % TOLERANCE Vector of tolerances to iterate through.
    %   The tolerance is used by the analysis functions to determine the
    %   stopping point. Adding more tolerance will make the analysis functions
    %   cycle through the different tolerances if a convergence failure occurs.
    tolerance = [1e-5,1e-4,1e-3];

    % ITERATIONS Maximum number of iterations to perform at each analysis step.
    iterations = 10;

    % PRINT Print flag. Valid values are 0, 1, 2, 4, and 5.
    %   0: Print nothing.
    %   1: Print information on norms each time test is invoked.
    %   2: Print information on norms and number of iterations at end of
    %      successful test.
    %   4: Print the norms and the ΔU and R(U) vectors at each step.
    %   5: Return a successful test even if convergence is not achieved within
    %      the maximum number of iterations.
    print = 0;

    % NORMTYPE Set the norm type. 0 = max-norm, 1 = 1-norm, 2 = 2-norm, etc.
    normType = 2;
end
properties (Hidden, Constant)
    validTests  = {'NormDispIncr','EnergyIncr'};
    validPrints = [0 1 2 4 5];
end

methods
%--------------------------------- Constructor --------------------------------%
function obj = TestOptions(varargin)
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
function set.type(obj,type_in)
    assert(ischar(type_in),'Test method must be a character vector');
    check = strcmpi(type_in,obj.validTests);
    assert(any(check),'Unknown test method: %s',type_in);
    obj.type = obj.validTests{check};  % Ensure capitalization is correct
end

function set.tolerance(obj,tol_in)
    assert(isnumeric(tol_in) && isvector(tol_in),'Tolerances must be a numeric vector');
    obj.tolerance = tol_in;
end

function set.iterations(obj,iter_in)
    assert(isFloatInt(iter_in) && (iter_in > 0) && isscalar(iter_in),'Number of iterations must be a positive scalar integer')
    obj.iterations = iter_in;
end

function set.print(obj,print_in)
    assert(any(print_in == obj.validPrints),'Print flag must be one of the following values: %s',num2str(obj.validPrints))
    obj.print = print_in;
end

function set.normType(obj,norm_in)
    assert(isFloatInt(norm_in) && (norm_in >= 0) && isscalar(norm_in),'Norm type must be a scalar integer >= 0')
    obj.normType = norm_in;
end

%------------------------------- Write Tcl code -------------------------------%
function str = genTclCode(obj, i)
    str = sprintf('test %s %g %i %i %i', obj.type, obj.tolerance(i), obj.iterations, obj.print, obj.normType);
end


end %methods

end %classdef
