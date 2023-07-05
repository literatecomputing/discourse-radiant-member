import discourseComputed from "discourse-common/utils/decorators";

export default Ember.Component.extend({
  @discourseComputed("siteSettings.radiant_group_values")
  groupStuff(values) {
    window.console.log("this", values);
    return values;
  },
});
