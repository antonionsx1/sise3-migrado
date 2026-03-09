<template>
  <div class="detalle-overlay" @click.self="$emit('cerrar')">
    <div class="detalle-card">
      <h3>Detalle de Audiencia</h3>
      <div class="campo"><span>Expediente:</span> {{ audiencia.numeroExpediente }}</div>
      <div class="campo"><span>Tipo de Asunto:</span> {{ audiencia.tipoAsunto }}</div>
      <div class="campo"><span>Tipo de Procedimiento:</span> {{ audiencia.tipoProcedimiento }}</div>
      <div class="campo"><span>Fecha y Hora:</span> {{ formatFecha(audiencia.fechaHora) }}</div>
      <div class="campo"><span>Tipo de Audiencia:</span> {{ audiencia.tipoAudiencia }}</div>
      <div class="campo"><span>Secretario:</span> {{ audiencia.secretario }}</div>
      <div class="campo"><span>Partes Interesadas:</span> {{ audiencia.partesInteresadas }}</div>
      <div class="campo"><span>Agendado por:</span> {{ audiencia.personaQueAgenda }}</div>
      <div class="campo">
        <span>Estado:</span>
        <span class="estado-badge" :style="{ background: colorEstado(audiencia.estado) }">
          {{ audiencia.estado }}
        </span>
      </div>
      <button @click="$emit('cerrar')" class="btn-cerrar">Cerrar</button>
    </div>
  </div>
</template>

<script>
export default {
  name: 'DetalleAudiencia',
  props: {
    audiencia: { type: Object, required: true }
  },
  emits: ['cerrar'],
  methods: {
    formatFecha(fecha) {
      return new Date(fecha).toLocaleString('es-MX')
    },
    colorEstado(estado) {
      const colores = { Cancelada: '#e53e3e', Diferida: '#d69e2e', Celebrada: '#38a169' }
      return colores[estado] || '#3182ce'
    }
  }
}
</script>

<style scoped>
.detalle-overlay {
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.5);
  display: flex; align-items: center; justify-content: center;
  z-index: 100;
}
.detalle-card {
  background: white; border-radius: 8px;
  padding: 24px; min-width: 380px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.2);
}
h3 { margin: 0 0 16px; color: #2d3748; font-size: 1.2rem; }
.campo { margin-bottom: 10px; font-size: 0.95rem; }
.campo span:first-child { font-weight: 600; color: #4a5568; margin-right: 6px; }
.estado-badge {
  color: white; padding: 2px 10px;
  border-radius: 12px; font-size: 0.85rem;
}
.btn-cerrar {
  margin-top: 16px; width: 100%;
  padding: 8px; background: #4a5568;
  color: white; border: none;
  border-radius: 6px; cursor: pointer;
}
.btn-cerrar:hover { background: #2d3748; }
</style>
