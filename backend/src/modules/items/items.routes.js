import { Router } from "express";
import { validate } from "../../middleware/validate.js";
import { idParams } from "../../shared/validation.js";
import { listQuery } from "../../shared/pagination.js";
import { itemBody } from "./items.validation.js";
import * as service from "./items.service.js";

export const itemsRouter = Router();

itemsRouter.get("/", validate({ query: listQuery }), async (req, res) => {
  res.json(await service.listItems(req.validated.query));
});

itemsRouter.post("/", validate({ body: itemBody }), async (req, res) => {
  res.status(201).json({ data: await service.createItem(req.validated.body) });
});

itemsRouter.put(
  "/:id",
  validate({ params: idParams, body: itemBody }),
  async (req, res) => {
    res.json({
      data: await service.updateItem(
        req.validated.params.id,
        req.validated.body,
      ),
    });
  },
);
