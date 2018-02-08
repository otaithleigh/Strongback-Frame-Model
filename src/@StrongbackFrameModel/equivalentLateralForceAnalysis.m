function results = equivalentLateralForceAnalysis(obj)
%%EQUIVALENTLATERALFORCEANALYSIS Equivalent Lateral Force procedure (ASCE 7-10)
%
%   results = EQUIVALENTLATERALFORCEANALYSIS(obj) generates the design story
%       forces, shears, and allowable story drifts for the information in obj.
%
%   The struct results contains the following fields:
%
%   seismicResponseCoefficient      ; C_s (Section 12.8.1.1)
%   baseShear                       ; V (Section 12.8.1)
%   storyForce                      ; F_x (Section 12.8.3)
%   storyShear                      ; V_x (Section 12.8.4)
%   allowableDrift                  ; Delta_a (Table 12.12-1)
%

results = struct;

SDS = FEMAP695.mappedValue('SDS',obj.seismicDesignCategory);
SD1 = FEMAP695.mappedValue('SD1',obj.seismicDesignCategory);

approxFundamentalPeriod = 0.02*sum(obj.storyHeight)^0.75;

if SD1 <= 0.1
    Cu = 1.7;
elseif SD1 >= 0.4
    Cu = 1.4;
else
    Cu = interp1([0.1 0.15 0.2 0.3 0.4],[1.7 1.6 1.5 1.4 1.4],SD1);
end

if isempty(obj.fundamentalPeriod)
    obj.fundamentalPeriod = 0.02*sum(obj.storyHeight)^0.75;
elseif obj.fundamentalPeriod > Cu*approxFundamentalPeriod
    obj.fundamentalPeriod = Cu*approxFundamentalPeriod;
end

maxSeismicResponseCoefficient = SD1/(obj.fundamentalPeriod*obj.respModCoeff/obj.impFactor);
results.seismicResponseCoefficient = min(SDS/(obj.respModCoeff/obj.impFactor),...
                                         maxSeismicResponseCoefficient);

seismicWeight = sum(obj.storyMass)*obj.g;
results.baseShear = seismicWeight*results.seismicResponseCoefficient;

if obj.fundamentalPeriod <= 0.5
    k = 1;
elseif obj.fundamentalPeriod >= 2.5
    k = 2;
else
    k = interp1([0.5 2.5],[1 2],obj.fundamentalPeriod);
end

verticalDistributionFactor = (obj.storyMass*obj.g .* cumsum(obj.storyHeight).^k)/...
                          sum(obj.storyMass*obj.g .* cumsum(obj.storyHeight).^k);

results.storyForce = verticalDistributionFactor*results.baseShear;
results.storyShear = cumsum(results.storyForce, 'reverse');

results.allowableDrift = 0.020*obj.storyHeight;

end %function:equivalentLateralForceAnalysis
