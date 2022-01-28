import React from 'react';
import {css as emoCSS} from '@emotion/css';
import styled from '@emotion/styled';

const css = (...args) => ({className: emoCSS(...args)})

const Item = styled('li')(
    {
      position: 'relative',
      cursor: 'pointer',
      display: 'block',
      border: 'none',
      height: 'auto',
      textAlign: 'left',
      borderTop: 'none',
      lineHeight: '1em',
      color: 'rgba(0,0,0,.87)',
      fontSize: '1rem',
      textTransform: 'none',
      fontWeight: '400',
      boxShadow: 'none',
      padding: '.8rem 1.1rem',
      whiteSpace: 'normal',
      wordWrap: 'normal',
    },
    ({isActive, isSelected}) => {
      const styles = []
      if (isActive) {
        styles.push({
          color: 'rgba(0,0,0,.95)',
          background: 'rgba(0,0,0,.03)',
        })
      }
      if (isSelected) {
        styles.push({
          color: 'rgba(0,0,0,.95)',
          fontWeight: '700',
        })
      }
      return styles
    },
)
const onAttention = '&:hover, &:focus'

const Input = styled('input')(
    {
      width: '100%', // full width - icon width/2 - border
      fontSize: 14,
      wordWrap: 'break-word',
      lineHeight: '1em',
      outline: 0,
      whiteSpace: 'normal',
      minHeight: '2em',
      background: '#fff',
      display: 'inline-block',
      padding: '1em 2em 1em 1em',
      color: 'rgba(0,0,0,.87)',
      boxShadow: 'none',
      border: '1px solid rgba(34,36,38,.15)',
      borderRadius: '.30rem',
      transition: 'box-shadow .1s ease,width .1s ease',
      [onAttention]: {
        borderColor: '#96c8da',
        boxShadow: '0 2px 3px 0 rgba(34,36,38,.15)',
      },
    },
    ({isOpen}) =>
        isOpen
            ? {
              borderBottomLeftRadius: '0',
              borderBottomRightRadius: '0',
              [onAttention]: {
                boxShadow: 'none',
              },
            }
            : null,
)

const Label = styled('label')({
  fontWeight: 'bold',
  display: 'block',
  marginBottom: 10,
})

const BaseMenu = styled('ul')(
    {
      padding: 0,
      marginTop: 0,
      position: 'absolute',
      backgroundColor: 'white',
      width: '100%',
      maxHeight: '20rem',
      overflowY: 'auto',
      overflowX: 'hidden',
      outline: '0',
      transition: 'opacity .1s ease',
      borderRadius: '0 0 .28571429rem .28571429rem',
      boxShadow: '0 2px 3px 0 rgba(34,36,38,.15)',
      borderColor: '#96c8da',
      borderTopWidth: '0',
      borderRightWidth: 1,
      borderBottomWidth: 1,
      borderLeftWidth: 1,
      borderStyle: 'solid',
    },
    ({isOpen}) => ({
      border: isOpen ? null : 'none',
    }),
)

const Menu = React.forwardRef((props, ref) => (
    <BaseMenu innerRef={ref} {...props} />
))

function getStringItems(filter) {
  return getItems(filter).map(({name}) => name)
}

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms)
  })
}

async function getItemsAsync(filter, {reject}) {
  await sleep(Math.random() * 2000)
  if (reject) {
    // this is just so we can have examples that show what happens
    // when there's a request failure.
    throw new Error({error: 'request rejected'})
  }
  return getItems(filter)
}

const itemToString = (i) => (i ? i.name : '')

const menuStyles = {
  maxHeight: '180px',
  overflowY: 'auto',
  maxWidth: '300px',
  minWidth: '200px',
  backgroundColor: '#fafafa',
  position: 'absolute',
  zIndex: 1000,
  padding: 0,
  listStyle: 'none',
  // border: '1px solid gray',
}

const selectedItemIconStyles = {cursor: 'pointer'}

const comboboxStyles = {display: 'inline-block', marginLeft: '5px', width: '70em'}

const comboboxWrapperStyles = {
  display: 'inline-flex',
  flexWrap: 'wrap',
}

export {
  menuStyles,
  comboboxStyles,
  comboboxWrapperStyles,
  selectedItemIconStyles,
  Menu,
  Input,
  Item,
  Label,
  css,
  itemToString,
  getStringItems,
  getItemsAsync,
}
