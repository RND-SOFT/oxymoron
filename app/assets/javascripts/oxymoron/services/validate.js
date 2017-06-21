angular.module("oxymoron.services.validate", [])
  .factory('Validate', [function(){
    return function (form, errors){
      try {
        var $form = angular.element(document.querySelector('[name="'+form+'"]')).scope()[form];
      } catch(e) {
        var $form = {};
      }

      angular
        .element(document.querySelectorAll('.rails-errors')).remove();

      angular.forEach($form, function(ctrl, name) {
        if (name.indexOf('$') != 0) {
          angular.forEach(ctrl.$error, function(value, name) {
            ctrl.$setValidity(name, null);
          });
        }
      });


      angular.forEach(errors, function(errors_array, key) {

        var keys = [];

        keys.push(form+'[' + key + ']');
        keys.push(form+'[' + "'" + key + "'" + ']');

        var split = key.split('.')
        if (split.length == 2) {
          var k = split[0]
          var v = split[1]

          keys.push(form+'[' + k + '_attributes' + ']' + '[' + v + ']')
          keys.push(form+"['" + k + '_attributes' + "']" + "['" + v + "']")
        }


        angular.forEach(keys, function(form_key) {
          try {
            if ($form[form_key]) {
              $form[form_key].$setTouched();
              $form[form_key].$setDirty();
              $form[form_key].$setValidity('server', false);
            }
            
            angular
              .element(document.querySelector('[name="'+form_key+'"]'))
              .parent()
              .append('<div class="rails-errors" ng-messages="'+form_key+'.$error"><div ng-message="server">'+errors_array[0]+'</div></div>')
          } catch(e) {
            console.log(e)
            console.warn('Element with name ' + form_key + ' not found for validation.')
          }
        });


      });
    };
  }])