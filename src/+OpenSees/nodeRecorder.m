function str = nodeRecorder(fid, file, nodes, dofs, response)
%NODERECORDER
%
%

a = sprintf('recorder Node -file {%s} -node ', file);
b = sprintf('%i ', nodes);
c = sprintf('-dof ');
d = sprintf('%i ', dofs);
e = sprintf('%s', response);

str = [a b c d e];
fprintf(fid, '%s\n', str);
