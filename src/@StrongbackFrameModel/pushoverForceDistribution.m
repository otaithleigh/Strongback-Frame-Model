function F = pushoverForceDistribution(obj)
%% PUSHOVERFORCEDISTRIBUTION Calculate the force ratios for pushover analysis.
%
%   F = pushoverForceDistribution(obj) calculates the force ratios based on the
%       first mode of vibration and the mass distribution.
%
%   Ref. FEMA P695 Equation 6-4.
%

[~,eigenvecs] = obj.eigenvalues;

storyMass = zeros(obj.nStories, 1);
for i = 1:obj.nStories
    storyMass(i) = obj.nodalMass(i, 'left') + obj.nodalMass(i, 'right') + obj.nodalMass(i, 'lean');
end

F = storyMass .* eigenvecs;
if min(F) < 0
    F = -F;
end
F = F/max(F);

end
