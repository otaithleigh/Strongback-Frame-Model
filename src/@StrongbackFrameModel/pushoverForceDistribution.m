function F = pushoverForceDistribution(obj)
%% PUSHOVERFORCEDISTRIBUTION Calculate the force ratios for pushover analysis.
%
%   F = pushoverForceDistribution(obj) calculates the force ratios based on the
%       first mode of vibration and the mass distribution.
%
%   Ref. FEMA P695 Equation 6-4.
%

[~,eigenvecs] = obj.eigenvalues;

F = obj.storyMass .* eigenvecs;
if min(F) < 0
    F = -F;
end
F = F/max(F);

end
