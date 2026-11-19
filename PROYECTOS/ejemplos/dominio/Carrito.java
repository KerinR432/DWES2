package com.ejemplo.dominio;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

public class Carrito {
    private List<Producto> items = new ArrayList<>();

    public List<Producto> getItems() { return items; }
    public void setItems(List<Producto> items) { this.items = items; }

    public void agregar(Producto p) {
        // si ya existe, incrementa cantidad
        for (Producto existente : items) {
            if (existente.equals(p)) {
                existente.setCantidad(existente.getCantidad() + p.getCantidad());
                return;
            }
        }
        items.add(p);
    }

    public void eliminar(Long productoId) {
        items.removeIf(p -> p.getId().equals(productoId));
    }

    public BigDecimal total() {
        return items.stream()
                .map(p -> p.getPrecio().multiply(BigDecimal.valueOf(p.getCantidad())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    public int cantidadTotal() {
        return items.stream().mapToInt(Producto::getCantidad).sum();
    }

    public boolean estaVacio() { return items.isEmpty(); }

    @Override
    public String toString() {
        return "Carrito{items=" + items + ", total=" + total() + "}";
    }
}
