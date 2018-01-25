function plotDeflectedShape(results, f)

figure

pos_x = f*results.disp_x + results.coords_x;
pos_y = f*results.disp_y + results.coords_y;

plot(pos_x(end,:), pos_y(end,:), '.')

end
