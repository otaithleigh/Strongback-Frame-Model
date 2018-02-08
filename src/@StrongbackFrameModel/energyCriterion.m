function energy = energyCriterion(obj,results)
%% ENERGYCRITERION Calculate the energy collapse criterion

time = results.time;

M = [
    obj.nodalMass(1:obj.nStories, 'left')' ;
    obj.nodalMass(1:obj.nStories, 'right')';
    obj.nodalMass(1:obj.nStories, 'lean')';
];

u_dot     = results.energy_vel_x;
u_ddot_eq = results.groundMotion;

expression = u_dot*M.*u_ddot_eq;

E_EQ = -cumtrapz(time,expression);

u = results.energy_disp_y;
E_G = -u*M*obj.g;
E_G_norm = E_G - E_G(1);

% Absolute value b/c small (10^-7 kip*ft) fluctuations in E_EQ
% early on can mess up collapseIndex finding.
collapseIndex = find(E_G_norm > abs(E_EQ), 1);
if isempty(collapseIndex)
    collapseIndex = NaN;
    collapse = false;
else
    collapse = true;
end

energy = struct;
energy.collapse = collapse;
energy.collapseIndex = collapseIndex;
energy.earthquake   = E_EQ;
energy.gravity      = E_G;
energy.norm_gravity = E_G_norm;

end
