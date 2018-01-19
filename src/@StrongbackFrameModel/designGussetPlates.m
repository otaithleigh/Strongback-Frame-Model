function designGussetPlates(obj)
%designGussetPlates  Design the gusset plates
%
%   The design process was originally based on a "balanced design process" laid
%   out in Roeder et al. (2011). It has since been adapted and updated to the
%   ANSI/AISC 360-16 and ANSI/AISC 341-16 specifications.
%

% Left side
for iStory = 1:obj.nStories
  for iSide = 1:2
    for iPlate = 1:2
      obj.GussetPlates{iStory,iSide,iPlate} = designGussetPlate(obj,iStory,iSide,iPlate);
    end
  end
end

end

%==============================================================================%
function Plate = designGussetPlate(obj, story, side, num)

PlateSizes = SteelDesign.Constants.PlateSizes;

Plate = GussetPlate;
Plate.material = obj.PlateMat;

if (story == 1) && (num == 1)
    Plate.position = 'Corner';
    Beam.shape = SteelDesign.SteelSection('ZeroSize');
elseif (mod(story, 2) == 0) && (num == 1)
    Plate.position = 'Midspan';
    Beam = obj.FrameBeams{story-1};
elseif (mod(story, 2) == 0) && (num == 2)
    Plate.position = 'Corner';
    Beam = obj.FrameBeams{story};
elseif (mod(story, 2) ~= 0) && (num == 1)
    Plate.position = 'Corner';
    Beam = obj.FrameBeams{story-1};
else
    Plate.position = 'Midspan';
    Beam = obj.FrameBeams{story};
end
Plate.db = Beam.shape.d;

switch side
case 1
    Brace = obj.LeftBraces{story};
    switch Plate.position
    case 'Corner'
        Column = obj.LeftColumns{story};
    case 'Midspan'
        if (story == 1)
            Column = obj.TieBraces{story+1};
        elseif (story == obj.nStories)
            Column = obj.TieBraces{story-1};
        else
            Column = obj.TieBraces{story};
        end
    end
case 2
    Brace = obj.RightBraces{story};
    switch Plate.position
    case 'Corner'
        Column = obj.RightColumns{story};
    case 'Midspan'
        if (story == 1)
            Column = obj.TieBraces{story+1};
        elseif (story == obj.nStories)
            Column = obj.TieBraces{story-1};
        else
            Column = obj.TieBraces{story};
        end
    end
end

switch Column.shape.Type
case 'W'
    Plate.dc = Column.shape.d;
case 'HSS'
    Plate.dc = Column.shape.Ht;
end

Plate.alpha = Brace.alpha;
Plate.c     = Brace.shape.Ht/2;


% 1. Brace stuff ---------------------------------------------------------------
Ag = Brace.shape.A;     % Gross area of brace
Ry = Brace.material.Ry; % Expected yield strength factor
Fy = Brace.material.Fy; % Yield strength of brace

Put = Ry*Fy*Ag;         % Expected tensile capacity of brace (kip)

% 2. Brace-to-gusset connection ------------------------------------------------
FEXX = 70;                                  % Electrode strength of weld
NW   = 4;                                   % Number of welds in connection
w2   = Brace.shape.tdes;                    % Weld thickness
phi = 0.75;                                 % Resistance factor (brace-to-gusset)

Lc = Put/(phi*0.6*FEXX*NW*(sqrt(2)/2)*w2);  % Required connection length

% 3. Check brace base material -------------------------------------------------
Fu = Brace.material.Fu;             % Tensile strength
NS = 4;                             % Number of shear planes
t  = Brace.shape.tdes;              % Brace wall thickness

if ~(Put < (phi*0.6*Fu*NS*Lc*t))
    Lc = Put/(phi*0.6*Fu*NS*t);     % Required connection length
end

% Check minimum weld length
if Lc < Brace.shape.Ht
    Lc = Brace.shape.Ht;
end
Plate.Lc_req = Lc;

% 4. Size plate thickness ------------------------------------------------------
B = Brace.shape.B;          % Brace width
Bw = B + 2*Lc*tand(30);     % Whitmore width
Fy = Plate.material.Fy;     % Yield strength of plate
Fu = Plate.material.Fu;     % Tensile strength of plate

% Tension
phi = 0.9;                  % Resistance factor (plate yield capacity)
tp1 = Put/(phi*Fy*Bw);      % Required plate thickness (based on yield)

phi = 0.75;                 % Resistance factor (plate tensile capacity)
tp2 = Put/(phi*Fu*Bw);      % Required plate thickness (based on tension)

% Block shear
phi = 0.75;                                 % Resistance factor (block shear)
Lgv = 2*Lc;                                 % Length of plate area in shear
Ubs = 1;                                    % Block shear factor (uniform tensile stress)
tp3 = Put/(phi*(0.6*Fy*Lgv + Ubs*Fu*B));    % Required plate thickness (based on block shear)

tp_con = max([tp1, tp2, tp3]);              % Controlling plate thickness

% Select plate thickness from "reasonable" sizes
validPlates = PlateSizes(PlateSizes > tp_con);
tp = validPlates(1);
Plate.tp = tp;

% X. Check weld shear strength against plate capacity --------------------------
phi = 0.75;

% Effective length
if Lc <= 100*w2
    Leff = Lc;
elseif Lc <= 300*w2
    beta = min(1.2 - 0.002*(Lc/w2), 1.0);
    Leff = beta*Lc;
else
    Leff = 180*w2;
end
Awe = w2*Leff*NW;       % Effective weld area
Rn  = 0.60*FEXX*Awe;    % Nominal weld strength

Ry = Plate.material.Ry;
Fy = Plate.material.Fy;
Ru = 0.6*Ry*Fy*tp;

if phi*Rn < Ru
    warning('Welds not strong enough -- AISC 341-16 Sec. F2.4')
end

% 5. Dimension plate -----------------------------------------------------------
Plate.clr_min  = 5*w2;

opts = optimoptions('fsolve');
opts.Display = 'off';
% opts.UseParallel = true;

func = @(x) f(x, Plate);
x0 = [30*Plate.tp, 30*Plate.tp];
res = fsolve(func, x0, opts);

a = real(res(1));
b = real(res(2));

Plate.a = a;
Plate.b = b;

% 6. Check compression ---------------------------------------------------------

% Demand
L = Brace.storyHeight * cscd(Brace.alpha);     % Panel to panel length of brace
La = L - 2*(Plate.L2 + Plate.L4);                   % Estimated actual length of brace
results = SteelDesign.capacity(Brace.shape, La, Brace.material);
Puc = results.CompressiveCapacity;

% Capacity
phi = 0.9;

Iy = Plate.Bw * Plate.tp^3 / 12;
Ag = Plate.Bw * Plate.tp;
ry = sqrt(Iy/Ag);

Fy = Plate.material.Fy;
Fe = pi^2 * Plate.material.Es / ( Plate.Lave / ry )^2;

if Fy/Fe <= 2.25
    Fcr = 0.658^(Fy/Fe) * Fy;
else
    Fcr = 0.877 * Fe;
end

Pn = Fcr * Ag;

if phi*Pn < Puc
    warning('Plate {%i,%i,%i} not sufficient in compression:\n    phiPn = %g\n    Puc   = %g\n',story,side,num,phi*Pn,Puc);
end




function y = f(x, Plate)
    pl = Plate;

    pl.a = x(1);
    pl.b = x(2);

    y(1) = pl.lp - pl.Lc_req - pl.l_ex;
    y(2) = (pl.a - pl.ox)*tand(pl.alpha) + pl.oy - pl.b;
end


end
