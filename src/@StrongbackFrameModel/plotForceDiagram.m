function plotForceDiagram(obj, output, force, len, nEle)
%PLOTFORCEDIAGRAM
%
%   PLOTFORCEDIAGRAM(obj, output, force, len, nEle)
%
%   force: 'axial', 'shear', 'moment'
%   len:   length of member being plotted
%   nEle:  number of elements used to represent member being plotted.
%
%   Assumes `output` is from an OpenSees command that returns i and j values,
%       so it'll stack stuff as necessary.
%

figure

xl = sprintf('Distance along member, %s', obj.units.length);

switch lower(force)
case 'axial'
    yl = sprintf('Axial force, %s', obj.units.force);
case 'shear'
    yl = sprintf('Shear, %s', obj.units.force);
case 'moment'
    yl = sprintf('Moment, %s-%s', obj.units.force, obj.units.length);
end

x = linspace(0, len, nEle+1);
x = x(2:end-1);

% Duplicate and collate interior elements
x = [x;x];
x = x(:)';

% Reattach exterior elements
x =[0, x, len];


plot(x, output)
grid on

xlabel(xl)
ylabel(yl)

end
