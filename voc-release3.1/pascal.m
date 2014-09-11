function [ap] = pascal(cls, n)

% [ap1, ap2] = pascal(cls, n)
% Train and score a model with n components.

globals;
pascal_init;

model = pascal_train(cls, n);
%model.thresh  = min(-2, model.thresh); 
%[boxes1, boxes2] = pascal_test(cls, model, 'test', [VOCyear,'test']);
%ap1 = pascal_eval(cls, boxes1, 'test', ['boxes1_comp' num2str(n)]);
%ap2 = pascal_eval(cls, boxes2, 'test', ['boxes2_comp' VOCyear]);
%ap = [ap1 ap2];
1;