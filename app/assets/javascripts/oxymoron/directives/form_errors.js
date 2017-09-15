angular.module("oxymoron.directives.formErrors", []).directive('formErrors', [
  '$parse', function($parse) {
    return {
      restrict: 'A',
      require: ['^form'],
      scope: {
        formErrors: "="
      },
      link: function($scope, element, attrs, arg) {
        
        var form = arg[0];
        var dig = function(object, parents, cb) {
          if (object.invalid) {
            cb(object, parents);
          }

          _.each(_.keys(object), function(key) {
            var p, v;
            if (key === 'errors' || key === 'invalid') {
              return;
            }
            v = object[key];
            if (_.isArray(v)) {
              _.each(v, function(o, i) {
                var p;
                p = _.clone(parents || []);
                p.push(key + "[" + i + "]");
                dig(o, p, cb);
              });
            } else if (_.isObject(v)) {
              p = _.clone(parents || []);
              p.push("" + key);
              dig(v, p, cb);
            }
          });
        };

        return $scope.$watch(function() {
          return $scope.formErrors;
        }, function(data) {
          if (_.isUndefined(data)) {
            return;
          }
          return dig(data.nested_errors, void 0, function(o, parents) {
            var form_ctrl;
            form_ctrl = _.reduce(parents, (function(f, key) {
              return f[key];
            }), form);

            if (!form_ctrl) {
              return
            }

            _.each(o.errors, function(v, k) {
              var field;
              if (field = form_ctrl[k]) {
                field.$setTouched();
                field.$setDirty();
                field.$setValidity('server', false);
                field.message = _.first(v);
              }
            });
          });
        });
      }
    };
  }
]);

