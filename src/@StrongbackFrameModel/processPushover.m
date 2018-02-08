function results =  processPushover(obj,results,ELF)
%% PROCESSPUSHOVER Process pushover results

if ~strcmp(results.exitStatus,'Analysis Successful')
    warning('Analysis not successful; results may not be valid for post-processing')
end

baseShear = results.baseShear;
roofDrift = results.roofDrift;
totalDrift = results.story_disp_x;
storyDrift = results.storyDrift;

% Identify peak of curve
peakShear = max(baseShear);
peakIndex = find(baseShear == peakShear, 1);
peakTotalDrift = totalDrift(peakIndex,:);
peakStoryDrift = storyDrift(peakIndex,:);

% Separate out post-peak indices
postPeakIndex      = roofDrift > roofDrift(peakIndex);
[postPeakShear,IA] = unique(baseShear(postPeakIndex), 'stable');
postPeakTotalDrift = totalDrift(postPeakIndex,:);
postPeakTotalDrift = postPeakTotalDrift(IA,:);
postPeakStoryDrift = storyDrift(postPeakIndex,:);
postPeakStoryDrift = postPeakStoryDrift(IA,:);

peak80Shear      = 0.8*peakShear;
peak80TotalDrift = interp1(postPeakShear,postPeakTotalDrift,peak80Shear);
peak80StoryDrift = interp1(postPeakShear,postPeakStoryDrift,peak80Shear);

peakStoryDriftRatio   = peakStoryDrift./obj.storyHeight;
peak80StoryDriftRatio = peak80StoryDrift./obj.storyHeight;

prePeakIndex         = roofDrift < peakTotalDrift(obj.nStories);
[prePeakShear,IA]    = unique(baseShear(prePeakIndex), 'stable');
prePeakDrift         = roofDrift(prePeakIndex);
prePeakDrift         = prePeakDrift(IA);

% Calculated values
calcOverstr          = peakShear/ELF.baseShear;
designBaseShearDrift = interp1(prePeakShear,prePeakDrift,ELF.baseShear);
effectiveYieldDrift  = calcOverstr*designBaseShearDrift;
periodBasedDuctility = peak80TotalDrift(obj.nStories)/effectiveYieldDrift;

% Return results
results.peakShear               = peakShear;
results.peakTotalDrift          = peakTotalDrift;
results.peakStoryDriftRatio     = peakStoryDriftRatio;
results.peak80Shear             = peak80Shear;
results.peak80TotalDrift        = peak80TotalDrift;
results.peak80StoryDriftRatio   = peak80StoryDriftRatio;
results.calcOverstr             = calcOverstr;
results.effectiveYieldDrift     = effectiveYieldDrift;
results.periodBasedDuctility    = periodBasedDuctility;

end
