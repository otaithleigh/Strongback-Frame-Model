function str = eleRecorder(fid, file, elements, dofs, response)
%ELERECORDER
%
%

a = sprintf('recorder Element -file {%s} -ele ', file);
b = sprintf('%i ', elements);
if ~isempty(dofs)
    c = sprintf('-dof ');
    d = sprintf('%i ', dofs);
else
    c = '';
    d = '';
end
e = sprintf('%s', response);

str = [a b c d e];
fprintf(fid, '%s\n', str);
