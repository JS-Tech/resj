import ListController from "controllers/list_controller.js"

export default class extends ListController {
  static targets = [...ListController.targets, "itemTemplate", "name", "type" ];

  updateList(items) {
    let content = "";
    items.forEach((c) => {
      this.nameTarget.innerHTML = c.name;
      this.typeTarget.innerHTML = c.type;
      content += this.itemTemplateTarget.innerHTML;
    });
    return content;
  }

  updateMap() {
    // TODO
  }

  get itemPerPage() {
    return 1;
  }

}