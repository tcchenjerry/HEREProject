function []= my_save_figure_tight(h, fname)
%%
% set(gca, 'Position', get(gca, 'OuterPosition') - ...
%     get(gca, 'TightInset') * [-1 0 1 0; 0 -1 0 1; 0 0 1 0; 0 0 0 1]);
% 
% h = zeros(1,2);
% h(1) = annotation('rectangle', get(gca, 'Position'), 'Color', 'Magenta');
% %annotation('rectangle', get(gca, 'OuterPosition'), 'Color', 'Yellow');
% h(2) = annotation('rectangle', get(gca, 'Position') + ...
%            get(gca, 'TightInset') * [-1 0 1 0; 0 -1 0 1; 0 0 1 0; 0 0 0 1], ...
%            'Color', 'Red');
% 
% set(h,'LineWidth', 3);
% print(gcf, '-dpng', '-r0', fname);
% 
%%
% % make your figure boundaries tight:
 ti = get(gca,'TightInset')
 set(gca,'Position',[ti(1) ti(2) 1-ti(3)-ti(1) 1-ti(4)-ti(2)]);
% 
% % now you have a tight figure on the screen but if you directly 
% %do saveas (or print), MATLAB will still add the annoying white space.
% % To get rid of them, we need to adjust the ``paper size":
% 
set(gca,'units','centimeters')
pos = get(gca,'Position');
ti = get(gca,'TightInset');

set(gcf, 'PaperUnits','centimeters');
set(gcf, 'PaperSize', [pos(3)-ti(1)-ti(3) pos(4)-ti(2)-ti(4)]);
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperPosition',[0 0 pos(3)+ti(1)+ti(3) pos(4)+ti(2)+ti(4)]);

saveas(gcf, fname,'png'); 
print(gcf,'-dpng',fname); 

% saveas(h,fname);