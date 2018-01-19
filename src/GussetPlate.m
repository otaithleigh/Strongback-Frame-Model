classdef GussetPlate < handle
%GussetPlate  Short description

properties
    material SteelDesign.SteelMaterial
    position {mustBeMember(position,{'Corner', 'Midspan'})} = 'Corner' % Location of plate within frame.
    a                   % x-dimension of gusset plate
    b                   % y-dimension of gusset plate
    tp                  % thickness of gusset plate
    Whitmore_angle = 30 % angle (deg) used for determination of Whitmore width.
    Lc_req              % required connection length

    alpha               % angle (deg) of attached brace
    c                   % distance from centerline to extreme fiber of attached brace
    clr_min             % minimum clearance from side of brace to edge of plate
    db                  % depth of adjacent beam (in.)
    dc                  % depth of adjacent column (in.)
end
properties (Dependent)
    K       % Initial stiffness of representative rotational spring
    Fy      % Yield strength of representative rotational spring
    Bw      % Whitmore width (in.)
    L1      % Buckling length 1 (in.)
    L2      % Buckling length 2 (in.)
    L3      % Buckling length 3 (in.)
    L4      % Length from adjacent beam/column centroid to edge of plate
    Lave    % Average buckling length (in.)
    Lc      % Actual connection length
    lp      % Length from end of brace to imaginary corner of plate (in.)
    l_ex    % Length from imaginary corner of plate to start of connection (in.)
    ox      % Offset of brace centerline from gusset corner, x-direction (in.)
    oy      % Offset of brace centerline from gusset corner, y-direction (in.)
end

methods

function K = get.K(obj)
    K = (obj.material.Es / obj.Lave) * (obj.Bw * obj.tp^3)/12;
end

function Fy = get.Fy(obj)
    Fy = (obj.Bw * obj.tp^2)/6 * obj.material.Fy;
end

function Bw = get.Bw(obj)
    Bw = 2*obj.c + 2*obj.Lc*tand(obj.Whitmore_angle);
end

function L1 = get.L1(obj)
    % x1 = (obj.Lc*tand(30) + obj.c)*tand(obj.alpha);
    % L1 = obj.L2 - x1;

    e1 = obj.ox + obj.L2*cosd(obj.alpha) + (obj.Lc*tand(30) + obj.c)*(cosd(obj.alpha)^2-1)*cscd(obj.alpha);
    LL1_0 = -obj.ox*tand(obj.alpha) + obj.oy + (obj.Lc*tand(30) + obj.c)*secd(obj.alpha);
    L1 = e1*secd(obj.alpha) + min(LL1_0*cscd(obj.alpha), 0);
end

function L2 = get.L2(obj)
    if obj.ox > 0
        L2 = sqrt((obj.a-obj.ox)^2 + obj.b^2) - obj.lp;
    else
        L2 = sqrt(obj.a^2 + (obj.b-obj.oy)^2) - obj.lp;
    end
end

function L3 = get.L3(obj)
    % x3 = (obj.Lc*tand(30) + obj.c)*cotd(obj.alpha);
    % L3 = obj.L2 - x3;
    L3 = obj.L2 - (obj.c + obj.Lc*tand(30)) + obj.oy*cscd(obj.alpha);
end

function L4 = get.L4(obj)
    if obj.ox > 0
        L4 = obj.db/2 * cscd(obj.alpha);
    else
        L4 = obj.dc/2 * secd(obj.alpha);
    end
end

function Lave = get.Lave(obj)
    Lave = mean([obj.L1, obj.L2, obj.L3]);
end

function lp = get.lp(obj)
    switch obj.position
    case 'Corner'
        ap = obj.a - 8*obj.tp;
        bp = obj.b - 8*obj.tp;
        rho = ap/bp;
        yp = ap*sin(atan(rho*tand(obj.alpha)));
        xp = ap*sqrt(1 - (yp/bp)^2);

        beta = atan(-2/rho * sqrt(ap^2 / xp^2));
        Corr = obj.c*sin(beta)*cosd(obj.alpha);

        lp = sqrt(xp^2 + yp^2) + Corr;
    case 'Midspan'
        lp = (obj.b - 6*obj.tp)*cscd(obj.alpha) - obj.c*cotd(obj.alpha);
    end
end

function Lc = get.Lc(obj)
    Lc = obj.lp - obj.l_ex;
end

function l_ex = get.l_ex(obj)
    l_ex = (obj.c + obj.clr_min)*tand(obj.alpha);
end

function ox = get.ox(obj)
    ox = max(0.5*(obj.db * cotd(obj.alpha) - obj.dc), 0);
end

function oy = get.oy(obj)
    oy = max(0.5*(obj.dc * tand(obj.alpha) - obj.db), 0);
end

end

end
