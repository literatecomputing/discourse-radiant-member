import discourseComputed from "discourse-common/utils/decorators";

function splitGroup(item) {
  const x = item.split(":");
  return { group: x[0], required: x[1] };
}
export default Component.extend({
  @discourseComputed("siteSettings.radiant_group_values")
  groupStatus(values) {
    let required = values.split("|").map(splitGroup);
    return required;
  },
});
